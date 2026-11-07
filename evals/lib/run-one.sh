#!/usr/bin/env bash
# run-one.sh <scenario> <run>: one eval run. Called by run.sh with EVAL_* set.
set -uo pipefail
scenario=$1 run=$2
sdir="$EVAL_HERE/$EVAL_SKILL/$scenario"
out="$EVAL_OUT/$scenario/$run"; mkdir -p "$out"
work=$(mktemp -d "${TMPDIR:-/tmp}/eval-$scenario-XXXX")
export REPO="$work/repo" REMOTE="$work/remote.git" EVAL_GH_STATE="$work/gh" EVAL_LIB="$EVAL_HERE/lib"
mkdir -p "$work/bin" "$work/ghconfig"
cp "$EVAL_HERE/lib/fake-gh" "$work/bin/gh"
echo "$work" > "$out/workdir"

if ! (source "$EVAL_LIB/fixture.sh" && source "$sdir/setup.sh") > "$out/setup.log" 2>&1; then
  echo "SETUP_FAILED" > "$out/checks.txt"; echo "[$scenario #$run] setup failed, see $out/setup.log" >&2; exit 0
fi
mkdir -p "$REPO/.claude/skills"
for s in "$EVAL_SKILL" $(cat "$sdir/skills" 2>/dev/null); do
  cp -R "$EVAL_HERE/../skills/$s" "$REPO/.claude/skills/$s"
done
echo ".claude/" >> "$REPO/.git/info/exclude"
first_pr=$(jq .next_pr "$EVAL_GH_STATE/state.json")

start=$(date +%s)
(cd "$REPO" && env -u GH_TOKEN -u GITHUB_TOKEN -u GH_HOST \
  PATH="$work/bin:$PATH" GH_CONFIG_DIR="$work/ghconfig" GH_PROMPT_DISABLED=1 CLAUDE_CODE_ENABLE_TODO_TOOLS=1 \
  perl -e 'alarm shift; exec @ARGV' "$EVAL_TIMEOUT" \
  claude -p "$(cat "$sdir/prompt.txt")" \
    --model "$EVAL_MODEL" --effort "$EVAL_EFFORT" \
    --setting-sources project --settings '{"includeCoAuthoredBy":false}' --permission-mode bypassPermissions \
    --output-format stream-json --verbose --no-session-persistence \
    --max-budget-usd "$EVAL_BUDGET" < /dev/null) > "$out/transcript.jsonl" 2> "$out/stderr.txt"
echo $(( $(date +%s) - start )) > "$out/seconds"

cp -R "$EVAL_GH_STATE" "$out/gh"
(cd "$REPO" && git log --all --graph --format='%h %d %s' > "$out/git-graph.txt" 2>&1)
TRANSCRIPT="$out/transcript.jsonl" SKILL_DIR="$EVAL_HERE/../skills/$EVAL_SKILL" FIRST_NEW_PR=$first_pr \
  bash -c 'source "$EVAL_LIB/checks.sh"; source "$1/check.sh"' _ "$sdir" > "$out/checks.txt" 2>&1
fails=$(grep -c '^FAIL' "$out/checks.txt" || true)
echo "[$scenario #$run] $(grep -c '^PASS' "$out/checks.txt") pass, $fails fail" >&2
