#!/usr/bin/env bash
# rescore.sh <results dir>: rerun each saved recall run's check.sh against its
# transcript and the temp dir it left (repo, snapshot, guard log, fake gh), then
# rewrite summary.md. Use it after changing a check, instead of new runs.
set -uo pipefail
dir=$(cd "$1" && pwd)
here=$(cd "$(dirname "$0")/.." && pwd)
for t in "$dir"/*/*/transcript.jsonl; do
  r=$(dirname "$t"); sc=$(basename "$(dirname "$r")"); w=$(cat "$r/workdir")
  [ -d "$w/repo" ] || { echo "rescore.sh: $w is gone, skipping $sc #$(basename "$r")" >&2; continue; }
  REPO=$w/repo REMOTE=$w/remote.git EVAL_GH_STATE=$w/gh EVAL_HERE=$here EVAL_LIB=$here/lib EVAL_SKILL=recall \
    TRANSCRIPT=$t SKILL_DIR=$here/../skills/recall \
    bash -c 'source "$EVAL_LIB/checks.sh"; source "$1/check.sh"' _ "$here/recall/$sc" > "$r/checks.txt" 2>&1
done
bash "$here/lib/summarize.sh" "$dir" | tee "$dir/summary.md"
