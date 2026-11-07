source "$EVAL_HERE/comments/lib.sh"
check_skill_loaded
check_checker
# Labels: file, kind, text that must go (bad) or stay (good), and the code line the comment sits on.
check_comments bad "$(printf '%s\t%s\t%s\t%s\n' \
  src/store.mjs narration 'parse the file and return' '^  return JSON\.parse\(text\)\.tasks;' \
  src/tasks.mjs change-note 'now stores the due date' '^  const task = \{ id, title, done: false, \.\.\.\(due' \
  src/tasks.mjs banner '^// (-{10,}|Due dates)' '^/\*\*|^export function dueBefore' \
  src/dates.mjs todo 'TODO' '^export function parseDue')"
check_comments good "$(printf '%s\t%s\t%s\t%s\n' \
  src/store.mjs outside-why '//.*(BOM|Notepad)' '^  const text = readFileSync' \
  src/tasks.mjs public-contract - '^export function dueBefore' \
  test/due.test.mjs lint-suppression '^  // lint-ignore-next-line max-len$' - \
  src/tasks.mjs untouched '^  // mark the matching task done$' - \
  src/tasks.mjs untouched '^// Open tasks, in the order they were added\.$' - \
  src/cli.mjs untouched '^// first argument is the command, the rest are its arguments$' -)"
check_no_code_edits
if final_text | grep -Eiq 'relative dates|tomorrow'; then pass todo_reported; else fail todo_reported "the final reply does not list the removed TODO"; fi
