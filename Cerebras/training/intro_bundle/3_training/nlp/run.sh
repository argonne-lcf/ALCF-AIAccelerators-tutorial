#!/bin/bash

# NOTE: You can execute different experiments/models by changing the yaml file!
cszoo fit llama3_tiny_msl_2k.yaml 2>&1 | tee out.log
