# OpenStack LOCI

OpenStack LOCI is a project designed to quickly build Lightweight OCI
compatible images of OpenStack services based on Ubuntu.

Additionally, we produce a "wheels" image for
[requirements](https://github.com/openstack/requirements) containing all of the
packages listed in upper-constraints.txt.

The instructions below can be used for any OpenStack service currently targeted
by LOCI. For simplicity, we will continue to use Keystone as an example.

### Building locally

Note: To build locally, you will need a version of docker >= 17.05.0.

#### Base image
You need to start by building a base image for your distribution that
included the required build dependencies. Loci has included a collection
of Dockerfiles to get you started with building a base image. These
are located in the dockerfiles directory.

It's easy to build a base image:
``` bash
$ docker build . \
    -f Dockerfile.base \
    --build-arg FROM=ubuntu:jammy \
    --build-arg CEPH_REPO='deb https://download.ceph.com/debian-reef/ jammy main' \
    --tag base:ubuntu_jammy
```

#### Requirements image
The `requirements` image is where we put all the packages listed in the OpenStack
[upper constraints](https://opendev.org/openstack/requirements/src/branch/master/upper-constraints.txt)
together with their dependencies. This is a consistent set of packages so that if we install various
OpenStack components from this set of packages we can be sure they are compatible with each other.
In Loci we use multistage Dockerfile with the project image as a default target.
To build the `requirements` image use the following command
``` bash
$ docker build . \
    -f Dockerfile \
    --target requirements \
    --build-arg FROM=base:ubuntu_jammy \
    --build-arg PROJECT=requirements \
    --tag requirements:master-ubuntu_jammy
```

#### Project image
Then you can build the rest of the service images using this requirements image:
``` bash
$ docker build . \
    --build-arg FROM=base:ubuntu_jammy \
    --build-arg WHEELS=requirements:master-ubuntu_jammy \
    --build-arg PROJECT=keystone \
    --tag keystone:master-ubuntu_jammy
```
Here you can specify the `requirements` (WHEELS) image which is mounted during the build and is used
as a wheels repository. By default the `quay.io/airshipit/requirements:master-ubuntu_jammy`
is used.

If building behind a proxy, remember to use build arguments to pass these
through to the build:
``` bash
$ docker build . \
    --build-arg http_proxy=$http_proxy \
    --build-arg https_proxy=$https_proxy \
    --build-arg no_proxy=$no_proxy \
    --build-arg PROJECT=keystone \
    --tag keystone:master-ubuntu_jammy
```

For more advanced building you can use docker build arguments to define:
  * `FROM` The base Docker image to build from. Dockerfiles to bootstrap
     the base images can be found in the `dockerfiles` directory, and are
     a good starting point for customizing a base image.
  * `PROJECT` The name of the project to install.
  * `PROJECT_REPO` The git repo containing the OpenStack project the container
    should contain
  * `PROJECT_REF` The git ref, branch, or tag the container should fetch for
    the project
  * `PROJECT_RELEASE` The project branch to determine python dependencies
    (defaults to master)
  * `PROJECT_PIP_EXTRAS` python extras to use during project install.
  * `UID` The uid of the user that will be created (defaults to 42424).
  * `GID` The gid of the group that will be created (default to 42424).
  * `WHEELS` The location of the wheels Docker image. The image must contain
    wheels in the root directory. It is mounted while building other images.
    `[myregistry/]mydockernamespace/requirements[:tag]`
  * `PROFILES` The bindep profiles to specify to configure which packages get
    installed. This is a space separated list.
  * `PIP_PACKAGES` Specify additional python packages you would like installed.
    The only caveat is these packages must exist in WHEELS form. So if
    you wanted to include rpdb, you would need to have built that into your
    WHEELS.
  * `KEEP_ALL_WHEELS` Set this to `True` if you want to keep all packages, even
    not built ourselfs in the WHEELS image. This is useful for reproducible builds,
    as 3rd party libraries will be keept in the WHEELS image.
  * `PIP_ARGS` Specify additional pip parameters you would like.
  * `PIP_WHEEL_ARGS` Specify additional pip wheel parameters you would like.
    Default is PIP_ARGS.
  * `DIST_PACKAGES` Specify additional distribution packages you would like
    installed.
  * `EXTRA_BINDEP` Specify a bindep-* file to add in the container. It would
    be considered next to the default bindep.txt.
  * `EXTRA_PYDEP` Specify a pydep-* file to add in the container. It would
    be considered next to the default pydep.txt.
  * `REGISTRY_PROTOCOL` Set this to `https` if you are running your own
    registry on https, `http` if you are running on http, or leave it as
    `detect` if you want to re-use existing protocol detection.
  * `REGISTRY_INSECURE` Set this to `True` if your image registry is
    running on HTTPS with self-signed certificates to ignore SSL verification.
    (defaults to False)
  * `EXTRA_PROJECTS` extra projects to install from `loci/data` directory.
  * `HORIZON_EXTRA_PANELS` specify list of pannels to enable during horizon build.

This makes it really easy to integrate LOCI images into your development or
CI/CD workflow, for example, if you wanted to build an image from [this
PS](https://review.opendev.org/c/openstack/keystone/+/923324/) you could run:
``` bash
$ docker build . \
    --build-arg PROJECT=keystone \
    --build-arg PROJECT_REPO=https://review.opendev.org/openstack/keystone \
    --build-arg PROJECT_REF=refs/changes/24/923324/10 \
    --tag keystone:923324-10
```

To build cinder with lvm and ceph support you would run:
``` bash
$ docker build . \
    --build-arg PROJECT=cinder \
    --build-arg PROFILES="lvm ceph"
```

### Building from sources

It may be required to install library or other dependency that is present in upper-constraints.txt
from sources. It may be achieved by using the following approach:

* Clone all projects that you want to install to the loci/data directory
* The directory content will be copied during image build stage
* Use KEEP_ALL_WHEELS=True build arg to preserve all built wheels
  in requirements image. This will allow to have reproducable builds
  when same requirements image is used.

If pipy project name is different from python project name add your project into
mapping file scripts/python-custom-name-mapping.txt

### Customizing
The images should contain all the required assets for running the service. But
if you wish or need to customize the `loci/keystone` image that's great! We
hope to have built the images to make this as easy and flexible as possible. To
do this we recommend that you perform any required customization in a child
image using a pattern similar to:

``` Dockerfile
FROM quay.io/airshipit/keystone:master-ubuntu_jammy
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
