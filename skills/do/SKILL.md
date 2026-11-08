---
name: do
description: Run a task through a playbook that fixes its steps, the skills each step loads, and its report. Only when the user starts it, with /do <task> where slash commands work or by name; a playbook name first picks it.
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

When the task's first word names a playbook, use it. Otherwise pick from the request.

Read the playbook you picked.

## 2. Copy the steps

Run `scripts/steps <playbook>` from this skill's folder. It prints the playbook's steps, one per line. Add each line to the session's task list as its own item, in order, before any item of your own, with the whole line copied as printed. Where items have a title and a description, the line's first sentence is the title and the whole line the description. Every task gets the list, even a question answered in one read. Use the session's task-list or plan tool. Without one, write the lines as a checklist in `.evidence/<task>/steps.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints.

Then work the list in order. Mark each item done when its step is done, and leave the text you copied into it as it is. A step you decide not to do keeps that text, and `skip: <reason>` goes at the end of its title (after its text, where items have no title), so the user sees what was skipped and why. A skipped step goes back to to-do when the user later asks for it.

Done when the list holds every step of the playbook, before step 1 starts: before you load a skill a step names or change any other file.

## 3. Stay on

The playbook stays on for the rest of the session. On each new message:

- A follow-up on the same work continues the list.
- "new task", a request another playbook fits, or a step that says to switch: pick again (step 1) and open a new list.

## Reply

Every playbook ends with a **Reply** line that names what its report holds. Write every message to the user for a tech lead who did not watch the work:

- A question from the user is answered in the next reply, at the top, even while other work runs. Wrong: "the full answer on B will come with the final summary".
- The message holds where things stand and what needs the user. The work that got there (narration of steps, the playbook's name, which steps are done, test counts) stays in the task list, the evidence and the PR.
