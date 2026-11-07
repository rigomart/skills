// The fix for issue 12, checked against the run's final tree: ids stay unique after a task is done.
import { test } from "node:test";
import assert from "node:assert/strict";
const { addTask, completeTask } = await import(`${process.env.REPO}/src/tasks.mjs`);

test("a task added after one is done gets an unused id", () => {
  let list = addTask([], "Write docs").list;
  list = addTask(list, "Ship it").list;
  list = completeTask(list, 1);
  const { list: next, task } = addTask(list, "Tell the team");
  assert.equal(new Set(next.map((t) => t.id)).size, next.length);
  assert.ok(task.id > 2);
});
