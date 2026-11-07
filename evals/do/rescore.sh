#!/usr/bin/env bash
# rescore.sh <results dir>: rerun each saved run's check.sh with the current
# checks and print a fresh summary, without new claude runs. Use it after a
# check changes. A run whose temp dir is gone loses only note_cap.
set -uo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
dir=${1:?usage: rescore.sh <results dir>}
for out in "$dir"/*/*/; do
  [ -f "$out/transcript.jsonl" ] || continue
  scenario=$(basename "$(dirname "$out")")
  work=$(cat "$out/workdir" 2>/dev/null)
  TRANSCRIPT="$out/transcript.jsonl" REPO="$work/repo" REMOTE="$work/remote.git" EVAL_GH_STATE="$out/gh" \
    EVAL_HERE=$here EVAL_LIB="$here/lib" EVAL_SKILL=do SKILL_DIR="$here/../skills/do" \
    bash -c 'source "$EVAL_LIB/checks.sh"; source "$1/check.sh"' _ "$here/do/$scenario" > "$out/checks.txt" 2>&1
done
bash "$here/lib/summarize.sh" "$dir" | tee "$dir/summary.md"
