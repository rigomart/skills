source "$EVAL_HERE/comments/lib.sh"
check_skill_loaded
check_checker
# Labels: file, kind, text that must go (bad) or stay (good), and the code line the comment sits on.
check_comments bad "$(printf '%s\t%s\t%s\t%s\n' \
  src/tasks.mjs banner '^// --- priorities' - \
  src/tasks.mjs todo 'TODO' '^const PRIORITIES' \
  src/tasks.mjs narration 'sort by priority, then by id' '^  return list\.filter' \
  test/tasks.test.mjs test-narration 'add three tasks with mixed' '^  let \{ list \} = addTask\(\[\], "low one"' \
  src/tasks.mjs made-false 'Open tasks, in the order they were added' -)"
check_comments good "$(printf '%s\t%s\t%s\t%s\n' \
  src/tasks.mjs public-contract - '^export function addTask' \
  src/store.mjs outside-why '//.*(atomic|crash|truncat)' '^  writeFileSync\(`' \
  test/tasks.test.mjs lint-suppression '^  // lint-ignore-next-line max-len$' - \
  src/tasks.mjs untouched '^  // mark the matching task done$' - \
  src/cli.mjs untouched '^// first argument is the command, the rest are its arguments$' -)"
check_no_code_edits
if final_text | grep -Eiq 'own priorities|define.*priorities|custom priorities'; then pass todo_reported; else fail todo_reported "the final reply does not list the removed TODO"; fi
