#!/bin/bash
#
# Converts a HuggingFace Llama-3.3-8B-Instruct checkpoint into Cerebras
# format, then arranges it as a model_dir the trainer can resume from.
#
# This downloads roughly 16 GB into ./hf_ckpts/, so make sure you have the
# space and that HTTPS_PROXY is set (setup_env.sh does that for you).
#
# NOTE: the last line OVERWRITES ./llama3p3_8b_instruct.yaml. That file is an
# OUTPUT of this stage -- the config emitted alongside the converted
# checkpoint -- not an input. The copy shipped with the bundle is an example
# of what you should end up with.

set -e
cd "$(dirname "$0")"

mkdir -p hf_ckpts
hf download allura-forge/Llama-3.3-8B-Instruct --local-dir ./hf_ckpts/

mkdir -p cs_ckpts
# cs-2.9 is deliberate, NOT stale. Run `cszoo checkpoint convert --help` and
# look at the supported-conversions table: for llama, hf <-> cs tops out at
# cs-2.9. There is no hf -> cs-2.10 converter, so `--tgt-fmt cs-current` on a
# 2.10 install fails with "Conversion failed". A cs-2.9 checkpoint loads fine
# on 2.10.
cszoo checkpoint convert \
    --model llama \
    --src-fmt hf \
    --tgt-fmt cs-2.9 \
    --output-dir cs_ckpts/ \
    hf_ckpts/model.safetensors.index.json \
    --config hf_ckpts/config.json

# Harmless on this filesystem: the converter's temp cleanup can fail with
#   OSError: [Errno 16] Device or resource busy: '.nfs...'
# That is NFS refusing to delete a file that is still open. The checkpoint is
# written regardless, and cleanup.sh removes the leftover with cs_ckpts/.

mkdir -p model_dir
mv cs_ckpts/model_*.mdl model_dir/ckpt_0.mdl
mv cs_ckpts/config_* ./llama3p3_8b_instruct.yaml
