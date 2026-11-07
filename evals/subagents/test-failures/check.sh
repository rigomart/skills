source "$EVAL_HERE/subagents/lib.sh"
check_skill_loaded
check_spawned 2
check_model_fits_role runner
check_not_above_session
check_spawned_together
check_tasks_listed
loose=$(top_spawns | jq -r 'select((.prompt // "") | test("npm (run )?test|node --test") | not) | .description' | paste -sd, -)
if [ -n "$(top_spawns)" ] && [ -z "$loose" ]; then pass brief_has_command; else fail brief_has_command "no test command in the brief of: ${loose:-no spawn}"; fi
check_result_checked "rerun, or read of a test, source file or the raw log" \
  '(.name=="Bash" and (.input.command // "" | test("npm (run )?test|node --test|(cat|sed|grep|head|tail|nl) .*(packages/|\\.(log|output|txt)\\b)")))
   or (.name=="Read" and (.input.file_path // "" | test("packages/(core|sync)/(test|src)/|\\.(log|output|txt)$"))) or (.name=="Grep" and (.input.path // "" | test("packages|\\.(log|output|txt)$")))'
missed=""
for t in "rejects empty titles" "parses ISO due dates" "retries until the third attempt succeeds"; do
  reply_names "$t" || missed="$missed '$t'"
done
if [ -z "$missed" ]; then pass reported_failures; else fail reported_failures "reply misses$missed"; fi
wrong=$(final_text | grep -Ei 'parseDue returns a Date|retry gives up after the last attempt|keeps [0-9]+ titles|adds [0-9]+ remote tasks' | grep -Eiv 'pass|ok|✔' || true)
if [ -z "$wrong" ]; then pass no_false_failures; else fail no_false_failures "$(printf '%s' "$wrong" | head -2 | paste -sd'|' -)"; fi
