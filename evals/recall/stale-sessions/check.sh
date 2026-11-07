source "$EVAL_HERE/recall/lib.sh"
check_skill_loaded
check_no_real_chats
check_nothing_changed
check_read_chats
check_threads pr4='#4\b' pr5='#5\b' undo='undo'
# checked_live: successful gh calls that show #4's state and #5's checks now,
# not as the chats left them. #4's squash commit on main, seen in any tool's output, counts too.
pr4=$( { gh_ok | grep -E '^pr view (#?4|list-json|[^ ]*/pull/4)( |$)' | json_has 'state|merged|closed'
  gh_ok | grep -E '^pr list .*(--state[= ]|-s )(merged|closed)'
  gh_ok | grep -E '^pr list .*(--state[= ]|-s )all' | json_has 'state|merged|closed'; } | head -1)
[ -n "$pr4" ] || ! tool_output_has 'add --json output \(#4\)' || pr4="main's log"
pr5=$( { gh_ok | grep -E '^pr checks (#?5|due-dates|[^ ]*/pull/5)( |$)'
  gh_ok | grep -E '^pr (view (#?5|due-dates|[^ ]*/pull/5) |list ).*statusCheckRollup'
  gh_ok | grep -E '^run list' | grep -Ev -- '(-b|--branch)[= ]' ; gh_ok | grep -E '^run list .*(-b|--branch)[= ]due-dates'; } | head -1)
miss=""; [ -n "$pr4" ] || miss="$miss #4-state"; [ -n "$pr5" ] || miss="$miss #5-checks"
if [ -z "$miss" ]; then pass checked_live; else fail checked_live "no gh call for$miss"; fi
# status_matches_live: #4 merged, #5 passing, undo in PR #7.
bad=""
brief_lines '#4\b' | grep -qi 'merged' || bad="${bad}#4 not merged; "
brief_lines '#5\b' | grep -Eqi 'pass|green|success|✓|✅' || bad="${bad}#5 not passing; "
brief_lines 'undo' | grep -Eqi '#7\b|PR' || bad="${bad}undo not in PR #7; "
if [ -z "$bad" ]; then pass status_matches_live; else fail status_matches_live "${bad%; }"; fi
check_next_move
