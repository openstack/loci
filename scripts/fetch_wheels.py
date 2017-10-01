#!/usr/bin/env python

import json
import os
try:
    import urllib2
except ImportError:
    # python3
    from urllib import request as urllib2


def get_token(repo):
    url = "https://auth.docker.io/token?service=registry.docker.io&" \
          "scope=repository:{}:pull".format(repo)

    r = urllib2.Request(url=url)
    resp = urllib2.urlopen(r)
    resp_text = resp.read().decode('utf-8').strip()
    return json.loads(resp_text)['token']


def get_sha(repo, tag, registry, token):
    url = "http://{}/v2/{}/manifests/{}".format(registry, repo, tag)
    print(url)
    r = urllib2.Request(url=url)
    if token:
        r.add_header('Authorization', 'Bearer {}'.format(token))
    resp = urllib2.urlopen(r)
    resp_text = resp.read().decode('utf-8').strip()
    return json.loads(resp_text)['fsLayers'][0]['blobSum']


def get_blob(repo, tag, registry='registry.hub.docker.com', token=None):
    sha = get_sha(repo, tag, registry, token)
    url = "http://{}/v2/{}/blobs/{} ".format(registry, repo, sha)
    print(url)
    r = urllib2.Request(url=url)
    if token:
        r.add_header('Authorization', 'Bearer {}'.format(token))
    resp = urllib2.urlopen(r)
    return resp.read()


def get_wheels(url):
    r = urllib2.Request(url=url)
    resp = urllib2.urlopen(r)
    return resp.read()


def parse_image(full_image):
    if '/' in full_image:
        registry, image_with_tag = full_image.split('/', 1)
    else:
        registry = None
        image_with_tag = full_image

    if ':' in image_with_tag:
        image, tag = image_with_tag.rsplit(':', 1)
    else:
        image = image_with_tag
        tag = 'latest'

    if '/' in image:
        return registry, image, tag

    if registry:
        return None, '/'.join([registry, image]), tag
    else:
        return None, image, tag


def main():
    if 'WHEELS' in os.environ:
        wheels = os.environ['WHEELS']
    else:
        with open('/opt/loci/wheels', 'ro') as f:
            wheels = f.read()

    if wheels.startswith('/'):
        with open(wheels, 'r') as f:
            data = f.read()
    elif wheels.startswith('http'):
        data = get_wheels(wheels)
    else:
        registry, image, tag = parse_image(wheels)
        kwargs = dict()
        if registry:
            kwargs.update({'registry': registry})
        else:
            kwargs.update({'token': get_token(image)})
        data = get_blob(image, tag, **kwargs)

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
