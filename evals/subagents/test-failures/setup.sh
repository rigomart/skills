# Two packages, each with a long, noisy test suite. core fails "rejects empty
# titles" and "parses ISO due dates"; sync fails "retries until the third attempt succeeds".
git init -q --bare -b main "$REMOTE"
mkdir -p "$REPO" && git -C "$REPO" init -q -b main
git -C "$REPO" config user.name "Eval Dev"
git -C "$REPO" config user.email "dev@example.com"
git -C "$REPO" config commit.gpgsign false
git -C "$REPO" remote add origin "$REMOTE"
seed_gh_state
cd "$REPO"
mkdir -p packages/core/src packages/core/test packages/sync/src packages/sync/test
cat > package.json <<'EOF'
{
  "name": "tasks-monorepo",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": { "test": "npm test --workspaces" }
}
EOF
printf 'node_modules/\n' > .gitignore
printf '# tasks\n\nTwo packages: `core` (the task list) and `sync` (remote sync). Run a package'"'"'s tests with `npm test` in its folder.\n' > README.md
for p in core sync; do
  cat > packages/$p/package.json <<EOF
{
  "name": "@tasks/$p",
  "version": "0.1.0",
  "type": "module",
  "scripts": { "test": "node --test" }
}
EOF
done
cat > packages/core/src/tasks.mjs <<'EOF'
export function addTask(list, title) {
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false };
  return { list: [...list, task], task };
}

export function parseDue(text) {
  const [y, m, d] = text.split("-").map(Number);
  return new Date(Date.UTC(y, m, d));
}
EOF
cat > packages/core/test/tasks.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { addTask, parseDue } from "../src/tasks.mjs";

for (let i = 1; i <= 60; i++) {
  test(`addTask keeps ${i} titles in order`, () => {
    let list = [];
    for (let j = 0; j < i; j++) ({ list } = addTask(list, `task ${j}`));
    console.log(`[core] built a list of ${i} tasks: ${list.map((t) => t.id).join(",")}`);
    assert.deepEqual(list.map((t) => t.title), Array.from({ length: i }, (_, j) => `task ${j}`));
  });
}

test("rejects empty titles", () => {
  assert.throws(() => addTask([], "   "), /title/);
});

test("parseDue returns a Date", () => {
  assert.ok(parseDue("2026-03-01") instanceof Date);
});

test("parses ISO due dates", () => {
  assert.equal(parseDue("2026-03-01").toISOString().slice(0, 10), "2026-03-01");
});
EOF
cat > packages/sync/src/retry.mjs <<'EOF'
export async function withRetry(fn, { tries = 3 } = {}) {
  let last;
  for (let i = 1; i < tries; i++) {
    try {
      return await fn(i);
    } catch (err) {
      last = err;
    }
  }
  throw last;
}

export function mergeTasks(local, remote) {
  const ids = new Set(local.map((t) => t.id));
  return [...local, ...remote.filter((t) => !ids.has(t.id))];
}
EOF
cat > packages/sync/test/sync.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { withRetry, mergeTasks } from "../src/retry.mjs";

for (let i = 1; i <= 60; i++) {
  test(`mergeTasks adds ${i} remote tasks`, () => {
    const remote = Array.from({ length: i }, (_, j) => ({ id: j + 100, title: `remote ${j}` }));
    const merged = mergeTasks([{ id: 1, title: "local" }], remote);
    console.log(`[sync] merged ${i} remote tasks into ${merged.length}`);
    assert.equal(merged.length, i + 1);
  });
}

test("retry gives up after the last attempt", async () => {
  await assert.rejects(withRetry(async () => { throw new Error("down"); }), /down/);
});

test("retries until the third attempt succeeds", async () => {
  const result = await withRetry(async (attempt) => {
    if (attempt < 3) throw new Error(`attempt ${attempt} failed`);
    return "ok";
  });
  assert.equal(result, "ok");
});
EOF
commit "feat: add core and sync packages"
git push -q -u origin main 2>/dev/null
git -C "$REMOTE" symbolic-ref HEAD refs/heads/main
