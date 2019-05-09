#!/bin/bash -ex

curl -s --noproxy "*" -k ${APIC_URL}  | grep "href.*\.egg" | sed "s#.*href=\"\([^-]*\)\([^>]*\)\".*#url=${APIC_URL}\1\2\\noutput=\1.egg#g" | curl -k -K -
for f in *.egg; do
    easy_install -O2 $f
    rm $f
done
