#!/bin/bash
#
# The longer road: pull a SlimPajama shard down as Arrow, convert it to
# JSONL, then tokenize it into HDF5. This shows the shape of a real
# preprocessing pipeline, where your data does not arrive as a tidy
# HuggingFace dataset.
#
# DKYoon/SlimPajama-6B is ungated, so no HuggingFace credential is needed,
# but this does download several GB. See the note in ../nlp_from_hf/run.sh
# about the harmless 'raw_chars_count' error near the end.

set -e
cd "$(dirname "$0")"

# cleanup.sh removes these, so recreate them before the scripts write into them.
mkdir -p 1_arrow 2_jsonl hf_cache

python download_slimpajama_shard.py
python arrow_to_jsonl.py
cszoo data_preprocess run --config preprocess.yaml
