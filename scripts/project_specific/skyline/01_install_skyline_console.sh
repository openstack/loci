#!/bin/bash

set -ex

SKYLINE_CONSOLE_DIR=/skyline-console

git clone -b ${SKYLINE_CONSOLE_REF} --depth 1 ${SKYLINE_CONSOLE_REPO} ${SKYLINE_CONSOLE_DIR}

(
    cd ${SKYLINE_CONSOLE_DIR}
    pip install -U .
)
