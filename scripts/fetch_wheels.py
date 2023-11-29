#!/usr/bin/env python
import json
import os
import platform
import re
import ssl
from urllib import request as urllib2

DOCKER_REGISTRY = 'registry.hub.docker.com'

MANIFEST_V1 = 'application/vnd.oci.image.manifest.v1+json'
MANIFEST_V2 = 'application/vnd.docker.distribution.manifest.v2+json'
MANIFEST_V2_LIST = 'application/vnd.docker.distribution.manifest.list.v2+json'

ARCH_MAP = {
    'x86_64': 'amd64',
    'aarch64': 'arm64',
}


def strtobool(v):
    # Clone from the now-deprecated distutils
    return str(v).lower() in ("yes", "true", "t", "1")


def registry_urlopen(r):
    if strtobool(os.environ.get('REGISTRY_INSECURE', "False")):
        resp = urllib2.urlopen(r, context=ssl._create_unverified_context())
    else:
        resp = urllib2.urlopen(r)
    return resp


def registry_request(r, token=None):
    try:
        if token:
            r.add_header('Authorization', 'Bearer {}'.format(token))
        return registry_urlopen(r)
    except urllib2.HTTPError as err:
        if err.reason == 'Unauthorized' and token is None:
            value = err.headers['www-authenticate'].split(' ', 2)
            items = urllib2.parse_http_list(value[1])
            opts = urllib2.parse_keqv_list(items)

            url = "{}?service={}&scope={}".format(
                opts['realm'],
                opts['service'],
                opts['scope']
            )

            auth_request = urllib2.Request(url=url)
            resp = registry_urlopen(auth_request)
            resp_text = resp.read().decode('utf-8').strip()
            token = json.loads(resp_text)['token']

            return registry_request(r, token)
        raise


def get_sha(repo, tag, registry, protocol):
    headers = {
        'Accept': ', '.join([MANIFEST_V2_LIST, MANIFEST_V2, MANIFEST_V1])
    }
    url = "{}://{}/v2/{}/manifests/{}".format(protocol, registry, repo, tag)
    print(url)
    r = urllib2.Request(url=url, headers=headers)
    resp = registry_request(r)
    resp_text = resp.read().decode('utf-8').strip()
    manifest = json.loads(resp_text)
    if manifest['schemaVersion'] == 1:
        return manifest['fsLayers'][0]['blobSum']
    elif manifest['schemaVersion'] == 2:
        if manifest['mediaType'] == MANIFEST_V2_LIST:
            arch = platform.processor()

            if arch not in ARCH_MAP:
                raise SystemError("Unknown architecture: %s" % arch)

            for m in manifest['manifests']:
                # NOTE(mnaser): At this point, we've found the digest for the
                #               manifest we want, we go back and run this code
                #               again but getting that arch-specific manifest.
                if m['platform']['architecture'] == ARCH_MAP[arch]:
                    tag = m['digest']
                    return get_sha(repo, tag, registry, protocol)

            # NOTE(mnaser): If we're here, we've gone over all the manifests
            #               and we didn't find one that matches our requested
            #               architecture.
            raise SystemError("Manifest does not include arch: %s" %
                              ARCH_MAP[arch])
        else:
            # NOTE(mnaser): This is the cause if the registry returns a manifest
            #               which isn't a list (single arch cases or getting
            #               a specific arch from a manifest list).  The V2
            #               manifest orders layers from base to end (as opposed
            #               to V1) so we need to get the last digest.
            return manifest['layers'][-1]['digest']
    raise SystemError("Unable to find correct manifest schema version")


def get_blob(repo, tag, protocol, registry=DOCKER_REGISTRY):
    sha = get_sha(repo, tag, registry, protocol)
    url = "{}://{}/v2/{}/blobs/{} ".format(protocol, registry, repo, sha)
    print(url)
    r = urllib2.Request(url=url)
    resp = registry_request(r)
    return resp.read()


def protocol_detection(registry, protocol='http'):
    PROTOCOLS = ('http', 'https')
    index = PROTOCOLS.index(protocol)
    try:
        url = "{}://{}".format(protocol, registry)
        r = urllib2.Request(url)
        urllib2.urlopen(r)
    except (urllib2.URLError, urllib2.HTTPError) as err:
        if err.reason == 'Forbidden':
            return protocol
        elif index < len(PROTOCOLS) - 1:
            return protocol_detection(registry, PROTOCOLS[index + 1])
        else:
            raise Exception("Cannot detect protocol for registry: {} due to error: {}".format(registry, err))
    else:
        return protocol


def get_wheels(url):
    r = urllib2.Request(url=url)
    resp = registry_request(r)
    # Using urllib2.request.urlopen() from python3 will face the IncompleteRead and then system report connect refused.
    # To avoid this problem, add an exception to ensure that all packages will be transmitted. before link down.
    try:
        buf = resp.read()
    except Exception as e:
        buf = e.partial
    return buf


def parse_image(full_image):
    slash_occurrences = len(re.findall('/', full_image))
    repo = None
    registry = DOCKER_REGISTRY
    if slash_occurrences > 1:
        full_image_list = full_image.split('/')
        registry = full_image_list[0]
        repo = '/'.join(full_image_list[1:-1])
        image = full_image_list[-1]
    elif slash_occurrences == 1:
        repo, image = full_image.split('/')
    else:
        image = full_image
    if image.find(':') != -1:
        image, tag = image.split(':')
    else:
        tag = 'latest'
    return registry, repo + '/' + image if repo else image, tag


def main():
    if 'WHEELS' in os.environ:
        wheels = os.environ['WHEELS']
    else:
        with open('/opt/loci/wheels', 'r') as f:
            wheels = f.read()

    if wheels.startswith('/'):
        with open(wheels, 'rb') as f:
            data = f.read()
    elif wheels.startswith('http'):
        data = get_wheels(wheels)
    else:
        registry, image, tag = parse_image(wheels)
        if os.environ.get('REGISTRY_PROTOCOL') in ['http', 'https']:
            protocol = os.environ.get('REGISTRY_PROTOCOL')
        elif os.environ.get('REGISTRY_PROTOCOL') == 'detect':
            protocol = protocol_detection(registry)
        else:
            raise ValueError("Unknown protocol given in argument")
        kwargs = dict()
        if registry:
            kwargs.update({'registry': registry})
        data = get_blob(image, tag, protocol, **kwargs)

    if 'WHEELS_DEST' in os.environ:
        dest = os.environ['WHEELS_DEST']
    else:
        with open('/opt/loci/wheels', 'w') as f:
            f.write(wheels)
        dest = '/tmp/wheels.tar.gz'
    with open(dest, 'wb') as f:
        f.write(data)


if __name__ == '__main__':
    main()
