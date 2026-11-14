#!/bin/bash
#
# NOTE: You can execute different experiments/models by changing CONFIG below,
# or by passing a config as the first argument:  ./run.sh mixtral_6x7b.yaml
# Any further arguments are passed straight through to cszoo, for example:
#     ./run.sh llama3_tiny_msl_2k.yaml --job_priority p3
# NOTE: --disable_version_check is only necessary as a quirk of this software
# release. We'll be able to remove it after our next upgrade (date TBD).

cd "$(dirname "$0")"
CONFIG="${1:-llama3_tiny_msl_2k.yaml}"

# The data_dir in these configs is filled in by configure_paths.sh, which
# setup_env.sh runs for you. Fail loudly rather than train on nothing.
if grep -q '__BUNDLE_ROOT__' "$CONFIG"; then
    echo "ERROR: $CONFIG still contains the __BUNDLE_ROOT__ placeholder." >&2
    echo "       Run ../../configure_paths.sh from the bundle root first." >&2
    exit 1
fi

cszoo fit "$CONFIG" --disable_version_check "${@:2}" 2>&1 | tee out.log
