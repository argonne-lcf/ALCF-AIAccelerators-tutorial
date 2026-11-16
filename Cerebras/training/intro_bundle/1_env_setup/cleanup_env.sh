#!/bin/bash
#
# Removes the virtual environment and the modelzoo checkout created by
# setup_env.sh. Run as `source cleanup_env.sh` so the `deactivate` applies
# to your current shell.

BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
VENV_ROOT="${CSBUNDLE_VENV:-$HOME/venvs}"

# Only defined if a virtual environment is currently active.
command -v deactivate >/dev/null 2>&1 && deactivate

rm -rf "$VENV_ROOT/cb-tutorial/"
rm -rf "$BUNDLE_ROOT/modelzoo/"
