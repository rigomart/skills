# Bug #12: a new task can reuse a taken id. Fix #13 (number after the highest id)
# merged and shipped in v0.3.1, then #14 reverted it in v0.3.2: stores from 0.2
# hold tasks with no id, and Math.max over them made every new id NaN. The issue
# is open again. An unrelated docs PR #15 is open. One past chat, from the revert.
source "$EVAL_HERE/recall/lib.sh"
recall_repo
cd "$REPO"
git tag v0.3.0 && git push -q origin v0.3.0 2>/dev/null

at 15
perl -pi -e 's/const id = list\.reduce\(\(max, t\) => Math\.max\(max, t\.id\), 0\) \+ 1;/const id = list.filter((t) => !t.done).length + 1;/' src/tasks.mjs
commit_push "refactor(tasks): number a new task after the open ones (#9)"

at 6
git switch -q -c fix-duplicate-ids
perl -pi -e 's/const id = list\.filter\(\(t\) => !t\.done\)\.length \+ 1;/const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;/' src/tasks.mjs
cat >> test/tasks.test.mjs <<'JS'

test("a new task never reuses an id after one is done", () => {
  let { list } = addTask([], "a");
  ({ list } = addTask(list, "b"));
  list = completeTask(list, 1);
  assert.equal(addTask(list, "c").task.id, 3);
});
JS
commit "fix(tasks): number a new task after the highest id"
git switch -q main; git merge -q --squash fix-duplicate-ids 2>/dev/null; commit "fix(tasks): number a new task after the highest id (#13)"
git branch -q -D fix-duplicate-ids
git tag v0.3.1; git push -q origin main v0.3.1 2>/dev/null

at 4
git revert --no-edit HEAD >/dev/null
git commit -q --amend -m 'revert: number a new task after the highest id (#14)' -m 'Reverts #13. Stores written by 0.2 hold tasks with no id, so Math.max returned NaN and every new task was added as #NaN.'
git tag v0.3.2; git push -q origin main v0.3.2 2>/dev/null

at 2; git switch -q -c docs-faq
printf '\n## FAQ\n\nTasks keep their ids when you mark them done.\n' >> README.md
commit_push "docs: add a FAQ"
git switch -q main

pr 13 fix-duplicate-ids MERGED "fix(tasks): number a new task after the highest id" "Fixes #12. A new task's id is one more than the highest id, not the count of open tasks."
pr 14 revert-13 MERGED "revert: number a new task after the highest id" "Reverts #13. Stores written by 0.2 hold tasks with no \`id\`, so \`Math.max\` returned NaN and every new task was added as \`#NaN\`. Reopening #12; the next fix has to handle tasks with no id."
pr 15 docs-faq OPEN "docs: add a FAQ" "A short FAQ in the README."
gh_json '.issues = {"12": {title: "A new task can get an id that is already taken", state: "OPEN",
  body: "After completing a task, the next task I add reuses an id: `tasks add a`, `tasks add b`, `tasks done 1`, `tasks add c` gives two tasks numbered #2.",
  comments: [{body: "Fixed by #13, released in v0.3.1."}, {body: "Reopening: #13 was reverted in #14 and v0.3.2."}]}}
  | .releases = [
    {tagName: "v0.3.2", name: "v0.3.2", publishedAt: "2026-11-03T15:00:00Z", isLatest: true, body: "Reverts the id fix from 0.3.1 (#14)."},
    {tagName: "v0.3.1", name: "v0.3.1", publishedAt: "2026-11-01T10:00:00Z", isLatest: false, body: "A new task no longer reuses an id (#13)."},
    {tagName: "v0.3.0", name: "v0.3.0", publishedAt: "2026-10-18T10:00:00Z", isLatest: false, body: "First release."}]'

recall_isolate
codex_session 4 2026-11-03T14-10-revert <<'CHAT'
U Since 0.3.1, tasks add prints "added #NaN" on a store file from 0.2. Find out why.
A Tasks saved by 0.2 have no id field. The fix in #13 takes Math.max over the ids, and Math.max with undefined is NaN, so every new task gets #NaN. Reverting #13 restores the old numbering, which brings back the duplicate ids from #12.
U Revert it and ship 0.3.2. When we fix #12 again, give tasks without an id one when the store loads.
A Merged the revert as #14, tagged v0.3.2 and reopened #12.
CHAT
snapshot
