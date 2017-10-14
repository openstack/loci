#!/bin/bash

set -ex

packages=$@

pip install --no-cache-dir --no-index --no-compile --upgrade --find-links /tmp/wheels/ ${packages}
