# The tasks repo with save() from src/store.mjs called directly, under an alias,
# through a namespace import, through a re-export and through a dispatch table,
# next to an unrelated cache.save() and a saveBackup() that only mentions save().
make_tasks_repo
seed_gh_state
cd "$REPO"
mkdir -p src/commands sync
cat > src/commands/add.mjs <<'EOF'
import { load, save } from "../store.mjs";
import { addTask } from "../tasks.mjs";

export function add(title) {
  const { list, task } = addTask(load(), title);
  save(list);
  return task;
}
EOF
cat > src/commands/done.mjs <<'EOF'
import { load, save as persist } from "../store.mjs";
import { completeTask } from "../tasks.mjs";

export function done(id) {
  const list = completeTask(load(), id);
  persist(list);
  return list;
}
EOF
cat > src/commands/clear.mjs <<'EOF'
import * as store from "../store.mjs";

// Drops every finished task and keeps the rest.
export function clear() {
  const open = store.load().filter((t) => !t.done);
  store.save(open);
  return open.length;
}
EOF
cat > src/cache.mjs <<'EOF'
const entries = new Map();

export const cache = {
  save(key, value) { entries.set(key, value); },
  get(key) { return entries.get(key); },
};

export function remember(key, value) {
  cache.save(key, value);
}
EOF
cat > sync/remote.mjs <<'EOF'
export async function upload(tasks) {
  const res = await fetch(process.env.TASKS_REMOTE, { method: "PUT", body: JSON.stringify({ tasks }) });
  if (!res.ok) throw new Error(`upload failed: ${res.status}`);
}
EOF
cat > sync/targets.mjs <<'EOF'
import { save } from "../src/store.mjs";
import { upload } from "./remote.mjs";

const writers = { local: save, remote: upload };

export function writeTo(target, tasks) {
  const write = writers[target];
  if (!write) throw new Error(`unknown target ${target}`);
  return write(tasks);
}
EOF
cat > sync/index.mjs <<'EOF'
export { load as readTasks, save as writeTasks } from "../src/store.mjs";
export { writeTo } from "./targets.mjs";
EOF
cat > sync/merge.mjs <<'EOF'
import { readTasks, writeTasks } from "./index.mjs";

export function mergeRemote(remoteTasks) {
  const local = readTasks();
  const ids = new Set(local.map((t) => t.id));
  const merged = [...local, ...remoteTasks.filter((t) => !ids.has(t.id))];
  writeTasks(merged);
  return merged;
}
EOF
cat > sync/backup.mjs <<'EOF'
import { copyFileSync } from "node:fs";
import { storePath } from "../src/store.mjs";

// Older versions called save() here before copying; the copy alone is enough.
export function saveBackup(dest) {
  copyFileSync(storePath(), dest);
  return "saved";
}
EOF
commit "feat: add commands, cache and sync"
git push -q origin main 2>/dev/null
