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

Open your reply with one line: `Playbook: <name>, because <reason>.`

## 2. Copy the steps

Open the playbook and add each numbered step to the session's task list as its own item, the text copied word for word, before any item of your own. Use the task-list tool the session has (`TaskCreate` or `TodoWrite` in Claude Code, the plan tool in Codex). Without one, write the list as a Markdown checklist to `.evidence/<task>/steps.md`, kept out of git through the file `git rev-parse --git-path info/exclude` prints, tick it as you go, and link it in the reply.

Then work the list in order. Mark each item done when its step is done. A step you decide not to do keeps its text and gets `skip: <reason>` after it, so the user sees what was skipped and why.

Done when the list holds every step of the playbook, before you change any other file.

## 3. Stay on

The playbook stays on for the rest of the session. On each new message:

- A follow-up on the same work continues the list.
- "new task", a request another playbook fits, or a step that says to switch: pick again (step 1) and open a new list.

## Reply

Every playbook ends with a **Reply** line that names what its report holds. Write it short and plain, for a user who did not watch the work: what they now see or can do comes first, and each claim carries its evidence or says it is unproven.
