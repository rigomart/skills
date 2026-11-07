#!/usr/bin/env bash
# run.sh: run a skill's eval scenarios on a model and print pass rates per check.
#
#   evals/run.sh <skill> [--model ID] [--effort LEVEL] [--runs N] [--jobs N]
#                        [--only a,b] [--budget USD] [--timeout SECONDS]
#
# Each run builds the scenario's fixture in a temp dir, installs the skill as a
# project skill, and runs `claude -p` there with only project settings loaded,
# a fake gh on PATH and a local bare repo as origin. Results go to
# evals/results/<skill>/<timestamp>-<model>-<effort>/.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
skill=${1:-}; [ -n "$skill" ] || { sed -n '2,10p' "$0"; exit 2; }; shift
model=claude-haiku-5-5 effort=xhigh runs=3 jobs=4 only="" budget=3 timeout=1500
while [ $# -gt 0 ]; do
  case "$1" in
    --model) model=$2; shift 2 ;; --effort) effort=$2; shift 2 ;;
    --runs) runs=$2; shift 2 ;;   --jobs) jobs=$2; shift 2 ;;
    --only) only=$2; shift 2 ;;   --budget) budget=$2; shift 2 ;;
    --timeout) timeout=$2; shift 2 ;;
    *) echo "run.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done
[ -d "$here/$skill" ] || { echo "run.sh: no scenarios in evals/$skill" >&2; exit 2; }
[ -d "$here/../skills/$skill" ] || { echo "run.sh: no skill skills/$skill" >&2; exit 2; }

out="$here/results/$skill/$(date +%Y%m%d-%H%M%S)-$model-$effort"
mkdir -p "$out"
export EVAL_HERE=$here EVAL_SKILL=$skill EVAL_MODEL=$model EVAL_EFFORT=$effort \
  EVAL_BUDGET=$budget EVAL_TIMEOUT=$timeout EVAL_OUT=$out

for s in "$here/$skill"/*/; do
  name=$(basename "$s")
  [ -f "$s/setup.sh" ] || continue
  if [ -n "$only" ] && ! printf ',%s,' "$only" | grep -q ",$name,"; then continue; fi
  for r in $(seq 1 "$runs"); do echo "$name $r"; done
done | xargs -P "$jobs" -n 2 bash "$here/lib/run-one.sh"

bash "$here/lib/summarize.sh" "$out" | tee "$out/summary.md"
