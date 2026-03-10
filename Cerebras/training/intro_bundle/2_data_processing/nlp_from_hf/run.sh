#!/bin/bash

# NOTE: if you run into an error while (re)generating data, try running again
# and, when prompted to delete the input directory, enter yes!
# That seems to fix the issue -- I'm currently sorting out root cause.
cszoo data_preprocess run --config preprocess.yaml
