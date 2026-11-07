source "$EVAL_HERE/do/lib.sh"
check_picked build
check_steps build
# Steps 6 and 7 are the review rounds, which a copy change skips: without a
# Reviewer spawn, each must say why.
if subagent_spawns | jq -e -s 'any(.[]; "\(.description) \(.prompt)" | test("review"; "i"))' >/dev/null; then skip_review=""; else skip_review="6 7"; fi
check_skips build 1 "$skip_review" "" full
check_reply
