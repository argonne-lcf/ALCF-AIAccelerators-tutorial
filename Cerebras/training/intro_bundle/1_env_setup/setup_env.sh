#!/bin/bash
#
# Run this as `source setup_env.sh`, not `sh setup_env.sh`, so the virtual
# environment stays activated when the script finishes.
#
# To re-activate later, from anywhere:
#     source <bundle>/venvs/r2.10/bin/activate
#
# Set CSBUNDLE_VENV to put the virtual environment somewhere other than
# inside the bundle, e.g.  export CSBUNDLE_VENV=$HOME/venvs

# Resolve the bundle root from this script's own location, so the bundle
# works wherever you copied it to.
BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
VENV_ROOT="${CSBUNDLE_VENV:-$BUNDLE_ROOT/venvs}"
echo "Bundle root:  $BUNDLE_ROOT"
echo "Virtual env:  $VENV_ROOT/r2.10"

# Rewrite the __BUNDLE_ROOT__ placeholders in the training configs so they
# point at this copy of the bundle. Safe to run more than once.
"$BUNDLE_ROOT/configure_paths.sh"

# Needed to reach the internet from the ALCF cluster.
export HTTPS_PROXY='http://proxy.alcf.anl.gov:3128'
export HTTP_PROXY='http://proxy.alcf.anl.gov:3128'

# Create and initialize new virtual environment.
mkdir -p "$VENV_ROOT"
python3.11 -m venv "$VENV_ROOT/r2.10"
source "$VENV_ROOT/r2.10/bin/activate"

# Persist the proxy into the virtual environment, so that re-activating it in
# a later session still has internet access. Without this, stage 2 and stage 4
# fail to download in any shell where setup_env.sh was not sourced.
if ! grep -q 'proxy.alcf.anl.gov' "$VENV_ROOT/r2.10/bin/activate"; then
    cat >> "$VENV_ROOT/r2.10/bin/activate" <<'PROXY'

# Added by the training bundle's setup_env.sh -- needed to reach the
# internet from the ALCF cluster.
export HTTPS_PROXY='http://proxy.alcf.anl.gov:3128'
export HTTP_PROXY='http://proxy.alcf.anl.gov:3128'
PROXY
fi
# Doubles as a quick network connectivity check
pip install --upgrade pip

# Modelzoo setup. Skip the clone if it is already there, so that re-running
# this script does not fail on a non-empty directory.
if [ ! -d "$BUNDLE_ROOT/modelzoo/.git" ]; then
    git clone --branch Release_2.10.0 https://github.com/Cerebras/modelzoo.git "$BUNDLE_ROOT/modelzoo"
else
    echo "modelzoo already present at $BUNDLE_ROOT/modelzoo -- skipping clone"
fi

pip install -r "$BUNDLE_ROOT/modelzoo/requirements.txt"
pip install -e "$BUNDLE_ROOT/modelzoo/"

# Confirms the client stack can reach the Cerebras appliance.
cerebras_install_check --mgmt_namespace job-operator
