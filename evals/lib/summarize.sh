#!/usr/bin/env bash
# summarize.sh <results dir>: pass rate per scenario and check, then cost and time.
set -uo pipefail
dir=$1
echo "# $(basename "$(dirname "$dir")") on $(basename "$dir")"
echo
echo "| Scenario | Check | Passed |"
echo "| --- | --- | --- |"
for s in "$dir"/*/; do
  [ -d "$s" ] || continue
  name=$(basename "$s")
  cat "$s"/*/checks.txt 2>/dev/null | awk -v sc="$name" -v runs="$(ls -d "$s"/*/ | wc -l | tr -d ' ')" '
    /^(PASS|FAIL) / { n=$2; sub(/:$/, "", n); if (!(n in seen)) { order[++k]=n; seen[n]=1 } if ($1=="PASS") ok[n]++ }
    /^SETUP_FAILED/ { setup++ }
    END {
      if (setup) printf "| %s | setup | failed %d |\n", sc, setup
      for (i=1; i<=k; i++) { n=order[i]; flag=(ok[n]+0<runs)?" ⚠":""; printf "| %s | %s | %d/%d%s |\n", sc, n, ok[n]+0, runs, flag }
    }'
done
echo
echo "| Scenario | Run | Cost USD | Turns | Seconds |"
echo "| --- | --- | --- | --- | --- |"
for t in "$dir"/*/*/transcript.jsonl; do
  [ -f "$t" ] || continue
  run=$(basename "$(dirname "$t")"); sc=$(basename "$(dirname "$(dirname "$t")")")
  read -r cost turns <<<"$(jq -r 'select(.type=="result") | "\(.total_cost_usd // "?") \(.num_turns // "?")"' "$t" | tail -1)"
  echo "| $sc | $run | ${cost:-?} | ${turns:-?} | $(cat "$(dirname "$t")/seconds" 2>/dev/null) |"
done
echo
echo "Failure details:"
grep -H '^FAIL' "$dir"/*/*/checks.txt 2>/dev/null | sed "s|$dir/||" || echo "none"
