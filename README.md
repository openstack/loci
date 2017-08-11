# OpenStack LOCI

OpenStack LOCI is a project designed to quickly build Lightweight OCI
compatible images of OpenStack services.

Currently we build images for the following OpenStack projects:

  * [Cinder](https://github.com/openstack/loci-cinder)
  * [Glance](https://github.com/openstack/loci-glance)
  * [Heat](https://github.com/openstack/loci-heat)
  * [Keystone](https://github.com/openstack/loci-keystone)
  * [Neutron](https://github.com/openstack/loci-neutron)
  * [Nova](https://github.com/openstack/loci-nova)

Images are built in the Docker Hub automatically on each commit to LOCI and
also on every commit to the service itself. Using Keystone as an example, if
openstack/keystone or openstack/loci-keystone merges a commit then a new image
is built to provide a continuously updated set of images based on a number of
distributions. Additionally, individual repos may be used to build images for
development purposes or as part of a CI/CD workflow.

The instructions below can be used for any OpenStack service currently targeted
by LOCI. For simplicity, we will continue to use Keystone as an example.


### Keystone Image Layer Info
[![](https://images.microbadger.com/badges/version/openstackloci/keystone:debian.svg)](https://microbadger.com/images/openstackloci/keystone:debian "openstackloci/keystone:debian") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:debian.svg)](https://microbadger.com/images/openstackloci/keystone:debian "openstackloci/keystone:debian")

[![](https://images.microbadger.com/badges/version/openstackloci/keystone:ubuntu.svg)](https://microbadger.com/images/openstackloci/keystone:ubuntu "openstackloci/keystone:ubuntu") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:ubuntu.svg)](https://microbadger.com/images/openstackloci/keystone:ubuntu "openstackloci/keystone:ubuntu")

[![](https://images.microbadger.com/badges/version/openstackloci/keystone:centos.svg)](https://microbadger.com/images/openstackloci/keystone:centos "openstackloci/keystone:centos") [![](https://images.microbadger.com/badges/image/openstackloci/keystone:centos.svg)](https://microbadger.com/images/openstackloci/keystone:centos "openstackloci/keystone:centos")


### Building locally
It's really easy to build images locally for the distro of your choice. To
build an image you only need to run:
``` bash
$ docker build https://git.openstack.org/openstack/loci-keystone.git#:debian --tag keystone:debian
```

If building behind a proxy, remember to use build arguments to pass these through to the build:
``` bash
$ docker build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy \
    --build-arg no_proxy=$no_proxy https://git.openstack.org/openstack/loci-keystone.git#:debian \
    --tag keystone:debian
```

You can, of course, substitute `debian` with your distro of choice.

For more advanced building you can use docker build arguments to define:
  * The git repo containing the OpenStack project the container should contain, `PROJECT_REPO`
  * The git ref or branch the container should fetch for the project, `PROJECT_REF`
  * The git repo containing the common install scripts, `SCRIPTS_REPO`
  * The git ref or branch the container should fetch for the scripts, `SCRIPTS_REF`
  * To inject anything into the image before hand (sources.list, keys, etc),
    create a tarball and reference its location, `OVERRIDE`
  * The location of the wheels tarball. This accepts a url to a tarball or a Docker image name
    in the form of [myregistry/]mydockernamespace/requirements:debian, `WHEELS`

This makes it really easy to integrate LOCI images into your development or
CI/CD workflow, for example, if you wanted to build an image from [this
PS](https://review.openstack.org/#/c/418167/) you could run:
``` bash
$ docker build https://git.openstack.org/openstack/loci-keystone.git#:debian \
    --tag mydockernamespace/keystone-testing:418167-1 \
    --build-arg PROJECT_REF=refs/changes/67/418167/1
```

To build with the wheels from a private Docker registry rather than DockerHub run:
``` bash
$ docker build https://git.openstack.org/openstack/loci-keystone.git#:debian \
    --build-arg WHEELS=172.17.0.1:5000/mydockernamespace/keystone:debian
```

### Customizing
The images should contain all the required assets for running the service. But
if you wish or need to customize the `openstackloci/keystone` image that's
great! We hope to have built the images to make this as easy and flexible as
possible. To do this we recommend that you perform any required customisation
in a child image using a pattern similar to:

``` Dockerfile
FROM openstackloci/keystone:debian
MAINTAINER you@example.com

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends your-awesome-binary-package \
    && rm -rf /var/lib/apt/lists/*
```
