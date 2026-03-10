#!/bin/bash

python download_slimpajama_shard.py

python arrow_to_jsonl.py

cszoo data_preprocess run --config preprocess.yaml
