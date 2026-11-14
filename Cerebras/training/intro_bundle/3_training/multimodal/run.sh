#!/bin/bash

# This config reads its dataset from /software/cerebras/dataset/llava/, which
# is shared and read-only, so it needs no path configuration.

cd "$(dirname "$0")"
CONFIG="${1:-llava_7b_p1.yaml}"

cszoo fit "$CONFIG" --disable_version_check "${@:2}" 2>&1 | tee out.log
