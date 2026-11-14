#!/bin/bash

# Remove the directories themselves, not dir/* -- a glob skips dotfiles and
# leaves stale NFS entries behind, which makes the next run prompt to delete
# a non-empty output directory.
cd "$(dirname "$0")"

rm -rf 1_arrow/
rm -rf 2_jsonl/
rm -rf 3_h5/
rm -rf hf_cache/
