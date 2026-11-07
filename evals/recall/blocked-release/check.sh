source "$EVAL_HERE/recall/lib.sh"
check_skill_loaded
check_no_real_chats
check_nothing_changed
check_read_chats
check_threads release-pr-21='#21\b' json-16='#16\b|json' due-17='#17\b|due date'
# blocked_marked: a line marks the release blocked on npm auth.
if brief_lines 'block' | grep -Eqi '401|auth|token|npm'; then pass blocked_marked
else fail blocked_marked "no line marks it blocked on npm auth"; fi
# prior_fix_cited: how the same E401 was cleared last time, which only the 6-day-old chat says.
if brief | grep -Eqi 'granular|secret set|expir'; then pass prior_fix_cited
else fail prior_fix_cited "the brief leaves out how the E401 was cleared before"; fi
check_next_move
