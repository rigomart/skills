source "$EVAL_HERE/subagents/lib.sh"
check_skill_loaded
check_spawned 2
check_model_fits_role scout
check_not_above_session
check_spawned_together
check_tasks_listed
check_result_checked "read or search of src/ or sync/" \
  '(.name=="Read" and (.input.file_path // "" | test("/(src|sync)/"))) or (.name=="Grep" and ((.input.path // "") + " " + (.input.pattern // "") | test("src|sync|save|persist|write")))
   or (.name=="Bash" and (.input.command // "" | test("(grep|rg|sed|cat|head|awk|nl) .*(src|sync)")))'

# Each call site: file, the call's line as an ERE, and its code as the reply might quote it.
# A site counts as found when one reply line names its line number with the file or the code.
sites=$(printf '%s\t%s\t%s\n' \
  src/cli.mjs '^  save\(next\);' 'save(next)' \
  src/cli.mjs '^  save\(completeTask' 'save(completeTask' \
  src/commands/add.mjs '^  save\(list\);' 'save(list)' \
  src/commands/done.mjs '^  persist\(list\);' 'persist(list)' \
  src/commands/clear.mjs '^  store\.save\(open\);' 'store.save(open)' \
  sync/targets.mjs '^  return write\(tasks\);|^const writers' 'write(tasks)' \
  sync/merge.mjs '^  writeTasks\(merged\);' 'writeTasks(merged)')
reply=$(final_text)
missed=""
while IFS=$'\t' read -r file re code; do
  found=0
  for n in $(grep -En -- "$re" "$REPO/$file" | cut -d: -f1); do
    if printf '%s\n' "$reply" | grep -F -e "$(basename "$file")" -e "$code" | grep -Eq "(^|[^0-9])$n([^0-9]|$)"; then found=1; fi
  done
  [ "$found" = 1 ] || missed="$missed $file($code)"
done <<<"$sites"
if [ -z "$missed" ]; then pass found_all_sites; else fail found_all_sites "missing:$missed"; fi

# The decoys may be named only to rule them out.
listed=$(printf '%s\n' "$reply" | grep -E 'cache\.(mjs|save)|backup\.mjs|saveBackup' \
  | grep -Eiv "not|n't|unrelated|different|exclud|decoy|false|ignor|skip|other|comment|mention|own |separate|method" || true)
if [ -z "$listed" ]; then pass no_false_sites; else fail no_false_sites "$(printf '%s' "$listed" | head -2 | paste -sd'|' -)"; fi
