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
| fleet | several items at once, each with its own agent: a list of issues, "deal with the open issues", "finish what's pending for the release", "a fleet of agents to fix X, prototype Y and review Z" | [playbooks/fleet.md](playbooks/fleet.md) |
| build | one change to what something does or how it looks: a feature, an issue number, a refactor, a cleanup, a perf fix, a new project, a redesign, polish, layout, "looks terrible" | [playbooks/build.md](playbooks/build.md) |
| research | needs evidence gathered before it can be answered: "what's the best X", "how could we build X", "is X feasible", "should we keep or drop X", "validate these sources", "look into X" | [playbooks/research.md](playbooks/research.md) |
| general | everything else: a question the code or history answers in a read or two, an opinion, a status check, a chore, babysitting a PR | [playbooks/general.md](playbooks/general.md) |

When the first word after `/do` names a playbook, use it. Otherwise pick from the request.

Read the playbook you picked.

## 2. Copy the steps

Open the playbook and add each numbered step to the session's task list as its own item, the text copied word for word, before any item of your own. Use the session's task-list or plan tool. Without one, keep the list as a checklist in `.evidence/<task>/steps.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints.

Then work the list in order. Mark each item done when its step is done. A step you decide not to do keeps its text and gets `skip: <reason>` after it, so the user sees what was skipped and why. A skipped step goes back to to-do when the user later asks for it.

Done when the list holds every step of the playbook, before you change any other file.

## 3. Stay on

The playbook stays on for the rest of the session. On each new message:

- A follow-up on the same work continues the list.
- "new task", a request another playbook fits, or a step that says to switch: pick again (step 1) and open a new list.

## Reply

Every playbook ends with a **Reply** line that names what its report holds. Write every message to the user for a tech lead who did not watch the work:

- A question from the user is answered in the next reply, at the top, even while other work runs. Wrong: "the full answer on B will come with the final summary".
- The message holds where things stand and what needs the user. The work that got there (narration of steps, the playbook's name, which steps are done, test counts) stays in the task list, the evidence and the PR.
