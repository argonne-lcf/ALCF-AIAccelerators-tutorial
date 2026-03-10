#!/bin/bash

mkdir hf_ckpts
hf download allura-forge/Llama-3.3-8B-Instruct --local-dir ./hf_ckpts/

mkdir cs_ckpts
cszoo checkpoint convert \
    --model llama \
    --src-fmt hf \
    --tgt-fmt cs-2.5 \
    --output-dir cs_ckpts/ \
    hf_ckpts/model.safetensors.index.json \
    --config hf_ckpts/config.json

mkdir model_dir
mv cs_ckpts/model_*.mdl model_dir/ckpt_0.mdl
mv cs_ckpts/config_* ./llama3p3_8b_instruct.yaml
