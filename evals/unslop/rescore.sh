#!/usr/bin/env bash
# rescore.sh <results dir>: rerun each saved run's check.sh against its transcript and the workdir
# it left in $TMPDIR, then rewrite summary.md. Use it after fixing a check, instead of new runs.
# Runs don't save the first new PR number, so new_prs counts every PR in the fixture.
set -uo pipefail
dir=$(cd "$1" && pwd)
here=$(cd "$(dirname "$0")/.." && pwd)
skill=$(basename "$(dirname "$dir")")
for t in "$dir"/*/*/transcript.jsonl; do
  r=$(dirname "$t"); sc=$(basename "$(dirname "$r")"); w=$(cat "$r/workdir")
  [ -d "$w/repo" ] || { echo "rescore.sh: $w is gone, skipping $sc #$(basename "$r")" >&2; continue; }
  REPO=$w/repo REMOTE=$w/remote.git EVAL_GH_STATE=$w/gh EVAL_LIB=$here/lib EVAL_SKILL=$skill \
    TRANSCRIPT=$t SKILL_DIR=$here/../skills/$skill \
    bash -c 'source "$EVAL_LIB/checks.sh"; source "$1/check.sh"' _ "$here/$skill/$sc" > "$r/checks.txt" 2>&1
done
bash "$here/lib/summarize.sh" "$dir" | tee "$dir/summary.md"
