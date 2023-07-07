#!/usr/bin/env python

import json
import os
import re

try:
    import urllib2
except ImportError:
    # python3
    from urllib import request as urllib2

DOCKER_REGISTRY='registry.hub.docker.com'

def get_token(protocol, registry, repo):
    if registry == DOCKER_REGISTRY:
      authserver = 'auth.docker.io/token'
      service = 'registry.docker.io'
    elif registry.startswith('keppel'):
      authserver = '{}/keppel/v1/auth'.format(registry)
      service = registry.split(':')[0]
    else:
      authserver = "{}/v2/token".format(registry)
      service = registry.split(':')[0]
    url = "{}://{}?service={}&" \
            "scope=repository:{}:pull".format(protocol, authserver, service, repo)
    try:
        r = urllib2.Request(url=url)
        resp = urllib2.urlopen(r)
        resp_text = resp.read().decode('utf-8').strip()
        return json.loads(resp_text)['token']
    except urllib2.HTTPError as err:
        if err.reason == 'Not Found':
            return None

def get_sha(repo, tag, registry, protocol, token):
    url = "{}://{}/v2/{}/manifests/{}".format(protocol, registry, repo, tag)
    r = urllib2.Request(url=url)
    r.add_header("Accept", "application/vnd.docker.distribution.manifest.v2+json")
    if token:
        r.add_header('Authorization', 'Bearer {}'.format(token))
    resp = urllib2.urlopen(r)
    resp_text = resp.read().decode('utf-8').strip()
    return json.loads(resp_text)['layers'][-1]['digest']


def get_blob(repo, tag, protocol, registry=DOCKER_REGISTRY, token=None):
    sha = get_sha(repo, tag, registry, protocol, token)
    url = "{}://{}/v2/{}/blobs/{}".format(protocol, registry, repo, sha)
    r = urllib2.Request(url=url)
    if token:
        r.add_unredirected_header('Authorization', 'Bearer {}'.format(token))
    resp = urllib2.urlopen(r)
    return resp.read()


def protocol_detection(registry, protocol='https'):
    PROTOCOLS = ('https','http')
    index = PROTOCOLS.index(protocol)
    try:
        url = "{}://{}".format(protocol, registry)
        r = urllib2.Request(url)
        resp = urllib2.urlopen(r)
    except (urllib2.URLError,urllib2.HTTPError) as err:
        if err.reason in ('Forbidden', 'Not Found'):
            return protocol
        elif index < len(PROTOCOLS) - 1:
            return protocol_detection(registry, PROTOCOLS[index + 1])
        else:
            raise Exception("Cannot detect protocol for registry: {} due to error: {}".format(registry,err))
    except:
        raise
    else:
        return protocol

def get_wheels(url):
    r = urllib2.Request(url=url)
    resp = urllib2.urlopen(r)
    return resp.read()

def parse_image(full_image):
    slash_occurrences = len(re.findall('/',full_image))
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
    return registry, repo+'/'+image if repo else image, tag

def main():
    if 'WHEELS' in os.environ:
        wheels = os.environ['WHEELS']
    else:
        with open('/opt/loci/wheels', 'rb') as f:
            wheels = f.read()

    if wheels.startswith('/'):
        with open(wheels, 'rb') as f:
            data = f.read()
    elif wheels.startswith('http'):
        data = get_wheels(wheels)
    else:
        registry, image, tag = parse_image(wheels)
        if os.environ.get('REGISTRY_PROTOCOL') in ['http','https']:
            protocol = os.environ.get('REGISTRY_PROTOCOL')
        elif os.environ.get('REGISTRY_PROTOCOL') == 'detect':
            protocol = protocol_detection(registry)
        else:
            raise ValueError("Unknown protocol given in argument")
        kwargs = dict()
        if registry:
            kwargs.update({'registry': registry})
        kwargs.update({'token': get_token(protocol, registry, image)})
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

