#!/usr/bin/env bash

# Don't delete build directory to enable incremental builds
# rm -rf ./build
# docker build -t dxvk .
docker run --rm -v "$(pwd)":/src -w /src dxvk \
            bash -c "./package-release.sh supersampling build"
