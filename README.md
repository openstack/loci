# OpenStack LOCI

OpenStack LOCI is a project designed to quickly build Lightweight OCI
compatible images of OpenStack services.

Currently we build and gate images for the following OpenStack projects:

  * [Cinder](https://github.com/openstack/cinder)
  * [Glance](https://github.com/openstack/glance)
  * [Heat](https://github.com/openstack/heat)
  * [Horizon](https://github.com/openstack/horizon)
  * [Ironic](https://github.com/openstack/ironic)
  * [Keystone](https://github.com/openstack/keystone)
  * [Neutron](https://github.com/openstack/neutron)
  * [Nova](https://github.com/openstack/nova)
  * [Octavia](https://github.com/openstack/octavia)

Additionally, we produce a "wheels" image for
[requirements](https://github.com/openstack/requirements) containing all of the
packages listed in upper-constraints.txt and custom-requirements.txt.

The instructions below can be used for any OpenStack service currently targeted
by LOCI. For simplicity, we will continue to use Keystone as an example.


### Keystone Image Layer Info
[![](https://images.microbadger.com/badges/version/loci/keystone:master-debian.svg)](https://microbadger.com/images/loci/keystone:master-debian "loci/keystone:master-debian") [![](https://images.microbadger.com/badges/image/loci/keystone:master-debian.svg)](https://microbadger.com/images/loci/keystone:master-debian "loci/keystone:master-debian")

[![](https://images.microbadger.com/badges/version/loci/keystone:master-ubuntu.svg)](https://microbadger.com/images/loci/keystone:master-ubuntu "loci/keystone:master-ubuntu") [![](https://images.microbadger.com/badges/image/loci/keystone:master-ubuntu.svg)](https://microbadger.com/images/loci/keystone:master-ubuntu "loci/keystone:master-ubuntu")

[![](https://images.microbadger.com/badges/version/loci/keystone:master-centos.svg)](https://microbadger.com/images/loci/keystone:master-centos "loci/keystone:master-centos") [![](https://images.microbadger.com/badges/image/loci/keystone:master-centos.svg)](https://microbadger.com/images/loci/keystone:master-centos "loci/keystone:master-centos")


### Building locally

Note: To build locally, you will need a version of docker >= 17.05.0.

It's really easy to build images locally:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git --build-arg PROJECT=keystone \
    --tag keystone:ubuntu
```

The default base distro is Ubuntu, however, you can use the following form to build from a distro of
your choice, in this case, CentOS:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git \
    --build-arg PROJECT=keystone \
    --build-arg WHEELS="loci/requirements:master-centos" \
    --build-arg FROM=centos:7 \
    --tag keystone:centos
```

If building behind a proxy, remember to use build arguments to pass these
through to the build:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git \
    --build-arg http_proxy=$http_proxy \
    --build-arg https_proxy=$https_proxy \
    --build-arg no_proxy=$no_proxy \
    --build-arg PROJECT=keystone \
    --tag keystone:ubuntu
```

For more advanced building you can use docker build arguments to define:
  * `FROM` The base Docker image to build from. Currently supported are
    `ubuntu:xenial`, `centos:7`, `opensuse/leap:15`, or a base image
    derived from one of those distributions. Dockerfiles to boostrap the
    base images can be found in the `dockerfiles` directory, and are a good
    starting point for customizing a base image.
  * `PROJECT` The name of the project to install.
  * `PROJECT_REPO` The git repo containing the OpenStack project the container
    should contain
  * `PROJECT_REF` The git ref, branch, or tag the container should fetch for
    the project
  * `UID` The uid of the user that will be created (defaults to 42424).
  * `GID` The gid of the group that will be created (default to 42424).
  * `WHEELS` The location of the wheels tarball. This accepts a url to a
    tarball or a Docker image name in the form of
    `[myregistry/]mydockernamespace/requirements[:ubuntu]`
  * `DISTRO` This is a helper variable used for scripts. It would primarily be
    used in situations where the script would not detect the correct distro.
    For example, you would set `DISTRO=centos` when running from an oraclelinux
    base image.
  * `PROFILES` The bindep profiles to specify to configure which packages get
    installed. This is a space separated list.
  * `PIP_PACKAGES` Specify additional python packages you would like installed.
    The only caveat is these packages must exist in WHEELS form. So if
    you wanted to include rpdb, you would need to have built that into your
    WHEELS.
  * `PIP_ARGS` Specify additional pip's parameters you would like.
  * `PIP_WHEEL_ARGS` Specify additional pip's wheel parameters you would like.
     Default is PIP_ARGS.
  * `DIST_PACKAGES` Specify additional distribution packages you would like
    installed.
  * `EXTRA_BINDEP` Specify a bindep-* file to add in the container. It would
     be considered next to the default bindep.txt.
  * `EXTRA_PYDEP` Specify a pydep-* file to add in the container. It would
     be considered next to the default pydep.txt.

This makes it really easy to integrate LOCI images into your development or
CI/CD workflow, for example, if you wanted to build an image from [this
PS](https://review.openstack.org/#/c/418167/) you could run:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git \
    --build-arg PROJECT=keystone \
    --tag mydockernamespace/keystone-testing:418167-1 \
    --build-arg PROJECT_REF=refs/changes/67/418167/1
```

To build with the wheels from a private Docker registry rather than DockerHub run:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git \
    --build-arg PROJECT=keystone \
    --build-arg WHEELS=172.17.0.1:5000/mydockernamespace/keystone:ubuntu
```

To build cinder with lvm and ceph support you would run:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git \
    --build-arg PROJECT=cinder \
    --build-arg PROFILES="lvm ceph"
```

### Customizing
The images should contain all the required assets for running the service. But
if you wish or need to customize the `loci/keystone` image that's great! We
hope to have built the images to make this as easy and flexible as possible. To
do this we recommend that you perform any required customisation in a child
image using a pattern similar to:

``` Dockerfile
FROM loci/keystone:master-ubuntu
MAINTAINER you@example.com

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends your-awesome-binary-package \
    && rm -rf /var/lib/apt/lists/*
```


### A Note on the Stability of LOCI
LOCI is considered stable. There are production installs of OpenStack using
LOCI built images at this time.

The project is very low-entropy with very little changing, but this is expected.
The highest traffic section of LOCI is the gates.
