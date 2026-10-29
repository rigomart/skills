---
name: do
description: Run a task through a playbook that fixes its steps, the skills each step loads, and its report. Type /do <task>, or /do <playbook> <task> to pick the playbook yourself.
disable-model-invocation: true
---

# Do

You run the task through one playbook. The playbook owns the order of the work, its review rounds and the report. The skills it names own how each step is done, so load each one when its step comes up, by name, without restating it.

## 1. Pick the playbook

| Playbook | The request | File |
| --- | --- | --- |
| build | changes what something does or how it looks: a feature, an issue number, a refactor, a cleanup, a perf fix, a new project, a redesign, polish, layout, "looks terrible" | [playbooks/build.md](playbooks/build.md) |
| general | everything else: a question, an opinion, a status check, a chore, babysitting a PR | [playbooks/general.md](playbooks/general.md) |

When the first word after `/do` names a playbook, use it. Otherwise pick from the request.

Open your reply with one short sentence that names the playbook, without the reason: `Using the general playbook.`

## 2. Copy the steps

Open the playbook and add each numbered step to the session's task list as its own item, the text copied word for word, before any item of your own. Use the task-list tool the session has (`TaskCreate` or `TodoWrite` in Claude Code, the plan tool in Codex). Without one, end every reply with one line that says where the steps stand: `Steps: 1–5 done, 6 skipped (one-line change), 7–9 to do.`

Then work the list in order. Mark each item done when its step is done. A step you decide not to do keeps its text and gets `skip: <reason>` after it, so the user sees what was skipped and why. A skipped step goes back to to-do when the user later asks for it.

Done when the list holds every step of the playbook, before you change any other file. Without a task-list tool, done when every reply ends with the steps line.

## 3. Stay on

The playbook stays on for the rest of the session. On each new message:

- A follow-up on the same work continues the list.
- "new task", a request another playbook fits, or a step that says to switch: pick again (step 1) and open a new list.

## Reply

Every playbook ends with a **Reply** line that names what its report holds. Write it short and plain, for a user who did not watch the work: what they now see or can do comes first, and each claim carries its evidence or says it is unproven.
