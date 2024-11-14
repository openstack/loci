# OpenStack LOCI

OpenStack LOCI is a project designed to quickly build Lightweight OCI
compatible images of OpenStack services.

Additionally, we produce a "wheels" image for
[requirements](https://github.com/openstack/requirements) containing all of the
packages listed in upper-constraints.txt.

The instructions below can be used for any OpenStack service currently targeted
by LOCI. For simplicity, we will continue to use Keystone as an example.

### Building locally

Note: To build locally, you will need a version of docker >= 17.05.0.

You need to start by building a base image for your distribution that
included the required build dependencies. Loci has included a collection
of Dockerfiles to get you started with building a base image. These
are located in the dockerfiles directory.

It's easy to build a base image:
``` bash
$ docker build dockerfiles/ubuntu \
    --build-arg FROM=ubuntu:jammy \
    --build-arg CEPH_REPO='deb https://download.ceph.com/debian-reef/ jammy main' \
    --tag loci-base:ubuntu_jammy
```

Then you can build the rest of the service images locally:
``` bash
$ docker build . \
    --build-arg FROM=loci-base:ubuntu_jammy \
    --build-arg PROJECT=keystone \
    --tag loci-keystone:master-ubuntu_jammy
```

The default base distro is Ubuntu Jammy, however, you can use the following form to build from a distro of your choice, in this case, CentOS:
``` bash
$ docker build dockerfiles/centos \
    --tag loci-base:centos

$ docker build . \
    --build-arg PROJECT=keystone \
    --build-arg WHEELS="loci/requirements:master-centos" \
    --build-arg FROM=loci-base:centos \
    --tag loci-keystone:master-centos
```

Loci will detect which base OS you're using, so if you need to add additional
features to your base image the Loci build will still run.

If building behind a proxy, remember to use build arguments to pass these
through to the build:
``` bash
$ docker build . \
    --build-arg http_proxy=$http_proxy \
    --build-arg https_proxy=$https_proxy \
    --build-arg no_proxy=$no_proxy \
    --build-arg PROJECT=keystone \
    --tag loci-keystone:master-ubuntu_jammy
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
  * `KEEP_ALL_WHEELS` Set this to `True` if you want to keep all packages, even
     not built ourselfs in the WHEEL image. Is useful for reproducible builts,
     as 3rd party libraries will be keept in WHEEL image.
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
    --tag loci-keystone:923324-10
```

To build with the wheels from a private Docker registry rather than Docker Hub run:
``` bash
$ docker build . \
    --build-arg PROJECT=keystone \
    --build-arg WHEELS=172.17.0.1:5000/mydockernamespace/requirements:master-ubuntu_jammy \
    --tag loci-keystone:master-ubuntu_jammy
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
FROM loci/keystone:master-ubuntu_jammy
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
