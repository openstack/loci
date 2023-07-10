#!/usr/bin/env python3

import json
import os
import re
import shutil
import tarfile

from pathlib import Path

from urllib import request as urllib2

DOCKER_REGISTRY = 'registry.hub.docker.com'


def get_token(protocol, registry, repo):
    if registry == DOCKER_REGISTRY:
        authserver = 'auth.docker.io/token'
        service = 'registry.docker.io'
    elif registry.startswith('keppel'):
        authserver = f'{registry}/keppel/v1/auth'
        service = registry.split(':')[0]
    else:
        authserver = f'{registry}/v2/token'
        service = registry.split(':')[0]
    url = f'{protocol}://{authserver}?service={service}&scope=repository:{repo}:pull'
    try:
        r = urllib2.Request(url=url)
        resp = urllib2.urlopen(r)
        resp_text = resp.read().decode('utf-8').strip()
        return json.loads(resp_text)['token']
    except urllib2.HTTPError as err:
        if err.reason == 'Not Found':
            return None


def get_sha(repo, tag, registry, protocol, token):
    url = f'{protocol}://{registry}/v2/{repo}/manifests/{tag}'
    r = urllib2.Request(url=url)
    r.add_header('Accept', 'application/vnd.docker.distribution.manifest.v2+json')
    if token:
        r.add_unredirected_header('Authorization', f'Bearer {token}')
    resp = urllib2.urlopen(r)
    resp_text = resp.read().decode('utf-8').strip()
    return json.loads(resp_text)['layers'][-1]['digest']


def get_blob_path(repo, tag, protocol, registry=DOCKER_REGISTRY, token=None):
    sha = get_sha(repo, tag, registry, protocol, token)
    sha_short = sha.rsplit(':')[-1]
    dest = get_fetch_wheels_cache_dir() / f'{sha_short}.tar.gz'

    if dest.exists():
        print(f'Using cached {dest}')
    else:
        print(f'Fetching {dest}')
        url = '{}://{}/v2/{}/blobs/{}'.format(protocol, registry, repo, sha)
        r = urllib2.Request(url=url)
        if token:
            r.add_unredirected_header('Authorization', f'Bearer {token}')

        with dest.open('wb') as out:
            with urllib2.urlopen(r) as resp:
                shutil.copyfileobj(resp, out, 1024 * 1024)

    return dest


def protocol_detection(registry, protocol='https'):
    PROTOCOLS = ('https', 'http')
    index = PROTOCOLS.index(protocol)
    try:
        url = '{}://{}'.format(protocol, registry)
        r = urllib2.Request(url)
        resp = urllib2.urlopen(r)
        resp.close()
    except (urllib2.URLError, urllib2.HTTPError) as err:
        if err.reason in ('Forbidden', 'Not Found'):
            return protocol
        elif index < len(PROTOCOLS) - 1:
            return protocol_detection(registry, PROTOCOLS[index + 1])
        else:
            raise Exception(
                f'Cannot detect protocol for registry: {registry} due to error: {err}')
    except:
        raise
    else:
        return protocol


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


def wheels_http_path(url):
    r = urllib2.Request(url=url)
    dest = get_fetch_wheels_cache_dir() / 'wheels.tar.gz'
    with urllib2.urlopen(r) as resp:
        with dest.open('wb') as out:
            shutil.copyfileobj(resp, out, 1024 * 1024)

    return dest


def get_oci_path(wheels):
    registry, image, tag = parse_image(wheels)
    if os.environ.get('REGISTRY_PROTOCOL') in ['http', 'https']:
        protocol = os.environ.get('REGISTRY_PROTOCOL')
    elif os.environ.get('REGISTRY_PROTOCOL') == 'detect':
        protocol = protocol_detection(registry)
    else:
        raise ValueError('Unknown protocol given in argument')
    kwargs = dict()
    if registry:
        kwargs.update({'registry': registry})
    kwargs.update({'token': get_token(protocol, registry, image)})
    return get_blob_path(image, tag, protocol, **kwargs)


def wheels_path(wheels):
    if wheels.startswith('/'):
        return Path(wheels)

    if wheels.startswith('http'):
        return wheels_http_path(wheels)

    return get_oci_path(wheels)


def get_wheels_source():
    if 'WHEELS' not in os.environ:
        with open('/opt/loci/wheels', 'rb') as f:
            return f.read()

    wheels = os.environ['WHEELS']
    with open('/opt/loci/wheels', 'w') as f:
        f.write(wheels)
    return wheels


def get_fetch_wheels_cache_dir():
    fetch_wheels_cache_dir = Path(os.environ.get('FETCH_WHEELS_CACHE_DIR',
                                                 '/tmp/fetch_wheels_cache'))
    fetch_wheels_cache_dir.mkdir(parents=True, exist_ok=True)
    return fetch_wheels_cache_dir


def get_wheels_dest():
    wheels_dest = Path(os.environ.get('WHEELS_DEST', '/tmp/wheels'))
    wheels_dest.mkdir(parents=True, exist_ok=True)
    return wheels_dest


def main():
    wheels = get_wheels_source()
    dest = get_wheels_dest()
    with wheels_path(wheels) as reader:
        with tarfile.open(reader, 'r|*') as tarstream:
            for ti in tarstream:
                if ti.name[0] == '.' or '/' in ti.name or (dest / ti.name).exists():
                    continue
                tarstream.extract(ti, dest)


if __name__ == '__main__':
    main()
