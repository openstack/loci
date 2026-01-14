At the moment the repository is used for building two sets of images using
slightly different pipelines: legacy and UV.

The legacy pipeline (see README.md) assumes building the base image,
the requirements image which contains all the wheels and then the
project images using the requirements image as the wheels repository.

The UV pipeline builds the base image, the python venv builder image and
the project images. The project image is built using two stages.
On the first stage the python venv is built using UV (modern fast python
package manager). Then on the second stage the python venv is copied to the
runtime image and also some binary packages are installed.

## Build images locally

### Base image
```bash
docker build . \
  -t quay.io/airshipit/base:2025.2-ubuntu_noble_uv \
  -f Dockerfile.base
```

### Venv builder image
```bash
docker build . \
  -t quay.io/airshipit/venv_builder:2025.2-ubuntu_noble_uv \
  -f Dockerfile.venv_builder \
  --build-arg FROM=quay.io/airshipit/base:2025.2-ubuntu_noble_uv
```

### Project image
```bash
PROJECT=<project>
PROJECT_REF=stable/2025.2
docker build . \
  -t quay.io/airshipit/${PROJECT}:2025.2-ubuntu_noble_uv \
  -f Dockerfile.runtime \
  --build-arg BASE_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble_uv \
  --build-arg BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble_uv \
  --build-arg PROJECT=${PROJECT} \
  --build-arg PROJECT_REF=${PROJECT_REF}
```

In many cases you would like to install additional packages listed explicitly or
use one of bindep profiles defined in pydep.txt and bindep.txt files. For this
you have to pass more build args. See which build-args are used in the playbooks/uv_vars.yaml.
