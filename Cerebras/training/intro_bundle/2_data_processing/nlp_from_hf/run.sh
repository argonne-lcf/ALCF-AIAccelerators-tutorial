#!/bin/bash
#
# Downloads karpathy/tiny_shakespeare and tokenizes it into HDF5 that the
# stage-3 training configs can read. Needs HTTPS_PROXY set, which
# setup_env.sh does for you. The dataset is ungated, so no HuggingFace
# credential is required.
#
# KNOWN COSMETIC ERROR: near the end you will see
#
#     ERROR ... Exception in write_remaining_prefix:
#     KeyError: 'raw_chars_count'
#
# This is a bug in modelzoo 2.10's statistics aggregation for the final
# partial chunk. The HDF5 files are written correctly before it happens --
# only a couple of averages in data_params.json are missing. You can safely
# ignore it; the data is fine.

cd "$(dirname "$0")"
cszoo data_preprocess run --config preprocess.yaml
