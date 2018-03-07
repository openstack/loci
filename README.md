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

Additionally, we produce a "wheels" image for
[requirements](https://github.com/openstack/requirements) containing all of the
packages listed in upper-constraints.txt and custom-requirements.txt.

The instructions below can be used for any OpenStack service currently targeted
by LOCI. For simplicity, we will continue to use Keystone as an example.


### Keystone Image Layer Info
[![](https://images.microbadger.com/badges/version/openstackloci/keystone:debian.svg)](https://microbadger.com/images/openstackloci/keystone:debian "openstackloci/keystone:debian") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:debian.svg)](https://microbadger.com/images/openstackloci/keystone:debian "openstackloci/keystone:debian")

[![](https://images.microbadger.com/badges/version/openstackloci/keystone:ubuntu.svg)](https://microbadger.com/images/openstackloci/keystone:ubuntu "openstackloci/keystone:ubuntu") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:ubuntu.svg)](https://microbadger.com/images/openstackloci/keystone:ubuntu "openstackloci/keystone:ubuntu")

[![](https://images.microbadger.com/badges/version/openstackloci/keystone:centos.svg)](https://microbadger.com/images/openstackloci/keystone:centos "openstackloci/keystone:centos") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:centos.svg)](https://microbadger.com/images/openstackloci/keystone:centos "openstackloci/keystone:centos")


### Building locally
It's really easy to build images locally for the distro of your choice. To
build an image you only need to run one of the following commands:
``` bash
$ docker build https://git.openstack.org/openstack/loci.git --build-arg PROJECT=keystone --tag keystone:ubuntu
$ docker build https://git.openstack.org/openstack/loci.git --build-arg PROJECT=keystone --tag keystone:centos --build-arg FROM=centos:7
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

You can, of course, substitute `ubuntu` with your distro of choice using the
FROM build arg.

For more advanced building you can use docker build arguments to define:
  * `FROM` The base Docker image to build from. Currently supported are
    ubuntu:xenial and centos:7
  * `PROJECT` The name of the project to install.
  * `PROJECT_REPO` The git repo containing the OpenStack project the container
    should contain
  * `PROJECT_REF` The git ref, branch, or tag the container should fetch for
    the project
  * `UID` The uid of the user that will be created (defaults to 42424).
  * `GID` The gid of the group that will be created (default to 42424).
  * `WHEELS` The location of the wheels tarball. This accepts a url to a
    tarball or a Docker image name in the form of
    [myregistry/]mydockernamespace/requirements[:ubuntu]
  * `DISTRO` This is a helper variable used for scripts. It would primarily be
    used in situations where the script would not detect the correct distro.
    For example, you would set DISTRO=centos when running from an oraclelinux
    base image.
  * `PROFILES` The bindep profiles to specify to configure which packages get
    installed. This is a space sperated list.
  * `PIP_PACKAGES` Specify additional python packages you would like installed.
    The only caveat is these packages must exist in WHEELS form. So if
    you wanted to include rpdb, you would need to have built that into your
    WHEELS.
  * `DIST_PACKAGES` Specify additional distribution packages you would like
    installed.

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
if you wish or need to customize the `openstackloci/keystone` image that's
great! We hope to have built the images to make this as easy and flexible as
possible. To do this we recommend that you perform any required customisation
in a child image using a pattern similar to:

``` Dockerfile
FROM openstackloci/keystone:master-ubuntu
MAINTAINER you@example.com

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends your-awesome-binary-package \
    && rm -rf /var/lib/apt/lists/*
```


### A Note on the Stability of LOCI
LOCI is still a relatively young project. While some of us have been using it
for going on a year, we have made breaking changes a few times while we flesh
out the best way to achieve goals. We are targeting a 1.0.0 release for
OpenStack Queens and will be following upstream practices as far as tagging and
branching.

We will be adding in a stable/ocata and stable/pike branch (possibly an
eol-newton and eol-mitaka tag as well) over the next few months so we can build
images for these versions of OpenStack as well. While the master branch of LOCI
is currently capable of building all of these versions right now, we will be
maintaining stable branches going forward so as not to rely on compatibility
for all versions of OpenStack on one branch.

We highly encourage people to use this, and some have even adopted it into
build pipelines internally already.
