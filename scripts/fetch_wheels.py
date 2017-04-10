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


def get_sha(repo, tag):
    url = "https://registry.hub.docker.com/v2/{}/manifests/{}".format(repo, tag)
    r = urllib2.Request(url=url)
    r.add_header('Authorization', 'Bearer {}'.format(get_token(repo)))
    resp = urllib2.urlopen(r)
    resp_text = resp.read().decode('utf-8').strip()
    return json.loads(resp_text)['fsLayers'][0]['blobSum']


def get_blob(repo, tag):
    sha = get_sha(repo, tag)
    url = "https://registry.hub.docker.com/v2/{}/blobs/{} ".format(repo, sha)
    r = urllib2.Request(url=url)
    r.add_header('Authorization', 'Bearer {}'.format(get_token(repo)))
    resp = urllib2.urlopen(r)
    return resp.read()


def get_wheels(url):
    r = urllib2.Request(url=url)
    resp = urllib2.urlopen(r)
    return resp.read()


repo = os.environ['DOCKER_REPO']
tag = os.environ['DOCKER_TAG']

with open('/tmp/wheels.tar.gz', 'wb') as f:
    if 'WHEELS' in os.environ:
        f.write(get_wheels(os.environ['WHEELS']))
    else:
        f.write(get_blob(repo, tag))
