#!/bin/bash
#
# Points the training configs at THIS copy of the bundle.
#
# The configs ship with a __BUNDLE_ROOT__ placeholder because stages 2-4
# write their output into the bundle, so you must copy the bundle somewhere
# writable before using it. This script fills the placeholder in.
#
#   ./configure_paths.sh           rewrite the configs for this location
#   ./configure_paths.sh --check   show what the configs currently point at
#
# Running it more than once is harmless, and running it after moving the
# bundle re-points the configs at the new location.

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Paths inside the bundle that the configs refer to. Each is produced by an
# earlier stage and consumed by a later one.
TAILS=(
    "2_data_processing/nlp_from_hf/shakespeare_h5"
    "2_data_processing/nlp_from_arrow/3_h5"
)

CONFIGS=(
    "$ROOT/3_training/nlp/llama3_tiny_msl_2k.yaml"
    "$ROOT/3_training/nlp/llama3_8b_msl_2k.yaml"
    "$ROOT/3_training/nlp/mixtral_6x7b.yaml"
    "$ROOT/4_checkpoint_conversion/full_config.yaml"
)

if [ "${1:-}" = "--check" ]; then
    grep -Hn 'data_dir' "${CONFIGS[@]}" 2>/dev/null
    if grep -q '__BUNDLE_ROOT__' "${CONFIGS[@]}" 2>/dev/null; then
        echo
        echo "NOT CONFIGURED: run ./configure_paths.sh first."
        exit 1
    fi
    exit 0
fi

# If the configs are not writable, the reader is almost certainly running this
# from the shared read-only copy. Say so, rather than letting sed fail with a
# bare "Permission denied".
for cfg in "${CONFIGS[@]}"; do
    if [ -e "$cfg" ] && [ ! -w "$cfg" ]; then
        echo "ERROR: cannot write $cfg" >&2
        echo "" >&2
        echo "This looks like the shared, read-only copy of the bundle. Copy it" >&2
        echo "somewhere you can write to and work in the copy -- stages 2 to 4" >&2
        echo "write their output into the bundle. For example:" >&2
        echo "" >&2
        echo "    cp -r $ROOT ~/training_intro_bundle" >&2
        echo "    cd ~/training_intro_bundle && ./configure_paths.sh" >&2
        exit 1
    fi
done

changed=0
for cfg in "${CONFIGS[@]}"; do
    [ -f "$cfg" ] || continue
    before="$(cat "$cfg")"
    for tail in "${TAILS[@]}"; do
        # Replace whatever absolute prefix currently precedes the tail --
        # the __BUNDLE_ROOT__ placeholder, a stale path from whoever built
        # the bundle, or this bundle's previous location.
        sed -i "s#\(data_dir:[[:space:]]*\)[^[:space:]]*${tail}/\?#\1${ROOT}/${tail}/#" "$cfg"
    done
    [ "$before" = "$(cat "$cfg")" ] || { changed=$((changed+1)); }
done

echo "configure_paths.sh: bundle root is $ROOT"
echo "configure_paths.sh: updated $changed config file(s)"

if grep -q '__BUNDLE_ROOT__' "${CONFIGS[@]}" 2>/dev/null; then
    echo "WARNING: a __BUNDLE_ROOT__ placeholder survived:" >&2
    grep -Hn '__BUNDLE_ROOT__' "${CONFIGS[@]}" >&2
    exit 1
fi
