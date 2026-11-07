# On main with uncommitted edits to tracked files only: task priorities and an
# atomic save. The change also makes an untouched comment on listTasks false.
# check.sh lists the seeded comments.
source "$EVAL_HERE/comments/lib.sh"
make_comments_repo

cat > src/tasks.mjs <<'EOF'
// --- priorities -------------------------------------------------------------

// TODO: let users define their own priorities
const PRIORITIES = ["high", "normal", "low"];

/**
 * Adds a task to `list` and returns the new list and the task.
 * Throws when `priority` is not "high", "normal" or "low".
 */
export function addTask(list, title, { priority = "normal" } = {}) {
  if (!PRIORITIES.includes(priority)) {
    throw new Error(`priority must be one of ${PRIORITIES.join(", ")}`);
  }
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false, priority };
  return { list: [...list, task], task };
}

export function completeTask(list, id) {
  if (!list.some((t) => t.id === id)) throw new Error(`no task with id ${id}`);
  // mark the matching task done
  return list.map((t) => (t.id === id ? { ...t, done: true } : t));
}

const rank = (t) => PRIORITIES.indexOf(t.priority ?? "normal");

// Open tasks, in the order they were added.
export function listTasks(list) {
  // sort by priority, then by id
  return list.filter((t) => !t.done).sort((a, b) => rank(a) - rank(b) || a.id - b.id);
}
EOF

perl -0pi -e 's/import \{ readFileSync, writeFileSync, existsSync \} from "node:fs";/import { readFileSync, writeFileSync, existsSync, renameSync } from "node:fs";/; s/  writeFileSync\(path, JSON.stringify\(\{ tasks \}, null, 2\) \+ "\\n"\);/  \/\/ writeFileSync truncates first, so a crash mid-write would empty the file.\n  \/\/ rename() over an existing file is atomic on POSIX.\n  writeFileSync(`\${path}.tmp`, JSON.stringify({ tasks }, null, 2) + "\\n");\n  renameSync(`\${path}.tmp`, path);/' src/store.mjs

cat >> test/tasks.test.mjs <<'EOF'

test("high priority tasks list first", () => {
  // add three tasks with mixed priorities
  let { list } = addTask([], "low one", { priority: "low" });
  ({ list } = addTask(list, "urgent", { priority: "high" }));
  ({ list } = addTask(list, "plain"));
  // lint-ignore-next-line max-len
  assert.deepEqual(listTasks(list).map((t) => `${t.priority}:${t.title}`), ["high:urgent", "normal:plain", "low:low one"]);
});
EOF
snapshot_seed
