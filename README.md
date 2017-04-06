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
[![](https://images.microbadger.com/badges/version/yaodu/keystone:latest.svg)](https://microbadger.com/images/yaodu/keystone:latest "yaodu/keystone:latest") [![](https://images.microbadger.com/badges/image/yaodu/keystone:latest.svg)](https://microbadger.com/images/yaodu/keystone:latest "yaodu/keystone:latest")

[![](https://images.microbadger.com/badges/version/yaodu/keystone:ubuntu.svg)](https://microbadger.com/images/yaodu/keystone:ubuntu "yaodu/keystone:ubuntu") [![](https://images.microbadger.com/badges/image/yaodu/keystone:ubuntu.svg)](https://microbadger.com/images/yaodu/keystone:ubuntu "yaodu/keystone:ubuntu")

[![](https://images.microbadger.com/badges/version/yaodu/keystone:centos.svg)](https://microbadger.com/images/yaodu/keystone:centos "yaodu/keystone:centos") [![](https://images.microbadger.com/badges/image/yaodu/keystone:centos.svg)](https://microbadger.com/images/yaodu/keystone:centos "yaodu/keystone:centos")


### Building locally
It's really easy to build images locally for the distro of your choice. To
build an image you only need to run:
``` bash
$ docker build https://git.openstack.org/openstack/loci-keystone.git#:debian --tag keystone:latest
```
You can, of course, substitute `debian` with your distro of choice.

For more advanced building you can use docker build arguments to define:
  * The git repo containing the OpenStack project the container should contain, `PROJECT_REPO`
  * The git ref or branch the container should fetch for the project, `PROJECT_REF`
  * The git repo containing the common install scripts, `SCRIPTS_REPO`
  * The git ref or branch the container should fetch for the scripts, `SCRIPTS_REF`
  * To inject anything into the image before hand (sources.list, keys, etc),
    create a tarball and reference its location, `OVERRIDE`
  * The docker image name to use for the base requirements python wheels, `DOCKER_REPO`
  * The docker image tag to use for the base requirements python wheels, `DOCKER_TAG`
  * If present, rather than using a docker image containing OpenStack
    requirements a tarball will be used from the defined URL, `WHEELS`

This makes it really easy to integrate LOCI images into your development or
CI/CD workflow, for example, if you wanted to build an image from [this
PS](https://review.openstack.org/#/c/418167/) you could run:
``` bash
$ docker build https://git.openstack.org/openstack/loci-keystone.git#:debian \
    --tag mydockernamespace/keystone-testing:418167-1 \
    --build-arg PROJECT_REPO=http://git.openstack.org/openstack/keystone.git \
    --build-arg PROJECT_REF=refs/changes/67/418167/1
```


### Customizing
The images should contain all the required assets for running the service. But
if you wish or need to customize the `openstackloci/keystone` image that's
great! We hope to have built the images to make this as easy and flexible as
possible. To do this we recommend that you perform any required customisation
in a child image using a pattern similar to:

``` Dockerfile
FROM openstackloci/keystone:latest
MAINTAINER you@example.com

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends your-awesome-binary-package \
    && rm -rf /var/lib/apt/lists/*
```
