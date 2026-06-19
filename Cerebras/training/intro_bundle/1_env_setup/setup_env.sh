#!/bin/bash

# NOTE: make sure you run this script as `source setup.sh`, not `sh setup.sh`
# to make sure your environment is activated in one go.
# If you run with sh, or for activating the env at a later time, just run
# `source ../../venvs/r2.10/bin/activate`.

# Needed to access the internet from the ALCF cluster.
export HTTPS_PROXY='http://proxy.alcf.anl.gov:3128'                                                                                      
export HTTP_PROXY='http://proxy.alcf.anl.gov:3128'

# Create and initialize new virtual environment.
mkdir ../../venvs/
python3.11 -m venv ../../venvs/r2.10
source ../../venvs/r2.10/bin/activate
# Doubles as a quick network connectivity check
pip install --upgrade pip

# Modelzoo setup
git clone --branch Release_2.10.0 https://github.com/Cerebras/modelzoo.git ../modelzoo
# PEFT pin is only necessary for release 2.6-2.8
# printf "\npeft==0.17.1" >> ../modelzoo/requirements.txt
printf "\npsutil==7.1.3" >> ../modelzoo/requirements.txt

pip install -r ../modelzoo/requirements.txt
pip install -e ../modelzoo/
