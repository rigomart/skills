# Fleet

You own the queue: what runs, when, and what reaches the user. Each item's owner, a subagent, owns its work, its proof and what it hands back. The user owns decisions, picks and merges.

1. List the items. When a ledger for this work exists (see **Ledger**), resume from it and `gh pr list` instead. Read each issue with its comments. Drop an item a merged PR or a commit on the default branch already covers, and say which: search merged PRs and `git log origin/<default>` by the issue's symptom and the files it names, since a fix often never names its issue. Give each kept item a kind, which sets its playbook and what it hands back:
   - **change**: the result is decided. The `build` playbook, no prototype; hands back a PR.
   - **prototype**: the `build` playbook would prototype it (a redesign, a new logo, "options" or "directions"). Hands back variants on a local branch.
   - **research**: a review, audit, proposal or question the `research` playbook fits. Hands back its report.

   Only a change opens a PR. A prototype or research item pushes nothing until the user picks; the pick then makes it a change. Two changes that would edit the same lines, or where one builds on the other, go to one owner as one PR, or the second waits for the first to merge. Items that only share a file, each adding its own line to a router or its own test to a test file, run at once: the second to merge resolves a one-line conflict. Done when every item has a kind and is kept, joined to another, queued behind one, or dropped with a reason.
2. Write the ledger. From here on, update it on every event before you reply, and answer status questions from it, not from memory.
3. Ask once, numbered, recommendation first, every question the `implement` skill says to ask, across all items. Items no answer blocks don't wait for it.
4. Fetch, then start one owner per item, each in its own worktree from the latest default branch, with the **Owner brief** for its kind and the role and model the `subagents` skill gives it. Start each wave at once, within that skill's limits on agents running at once.
5. When an owner reports, spot-check one claim against its evidence, update the ledger and start the next queued item. For a change, check its PR is at the head it names (`gh pr view <n> --json headRefOid,files`) and watch the PR with the `babysit-pr` skill. For a prototype or research item, check nothing reached the remote (`git ls-remote --heads origin <branch>` prints nothing, and `gh pr list --head <branch>` is empty), then bring the user its variants or report. The user's pick goes back to that owner as a change: build the pick and open a PR. An owner that couldn't run its review: spawn a Reviewer (`subagents` skill) on its branch's diff with the item and the owner's evidence, and send the owner the findings. An owner's question goes to the user with any others pending, and the answer goes back to that owner. Edit, rebase and push nothing of an owner's yourself: everything its PR needs goes back to its owner, continued with its context. When it can't be continued, start a fresh owner on its branch with the original brief and what's new.
6. When a PR's checks or state change, handle it with the `babysit-pr` skill. When a PR merges, check the other open ones for a conflict or a stale base, and send each conflict to its owner.
7. Message the user only when an answer or a pick is needed, a PR is green and ready for their review, or every item is done, each time with the ledger as one line per item. An event that changes nothing for them gets no message.
8. Stop when every item is merged, closed, green and waiting on the user's review, or waiting on the user's pick, and stop watching every PR.

## Ledger

`.evidence/<fleet>/ledger.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints. One row per item:

| Item | Kind | Owner | PR | State | Next | Needs you |
| --- | --- | --- | --- | --- | --- | --- |
| #12 export fails on an empty list | change | how to reach the owner (its id or thread) | #40 | checks green | user review | merge; nothing before |
| #20 settings redesign | prototype | its id or thread | none until the pick | waiting on your pick | build the pick | pick a variant |

State is one of: queued, building, waiting on an answer, waiting on your pick, PR open, checks failing, ready for review, merged, dropped. A new session resumes from this file, so it carries everything the work needs that the PRs don't: settled decisions, items queued behind others, why an item was dropped.

## Owner brief

Fill in each `<...>`:

```text
<The item as a user would ask for it, with what it hands back.
 change: "Fix #12 (<url>) and open a PR against <default>."
 prototype: "Prototype directions for #20 (<url>). Commit them on a local branch; push nothing and open no PR until I pick."
 research: "Review <topic> and recommend. Report back; write no tracked doc, push nothing, open no PR.">

Follow the <build or research> playbook at <absolute path of this folder>/<build.md or research.md>. You may spawn the subagents it calls for.

Settled: <the user's answers and the decisions already made, or "none">. Other owners are changing <their files or areas> at the same time: <how to stay out of their way>.

Run one build or test command at a time, and stop every process you started before you report.
```

**Reply:** the ledger as one line per item, each with its PR link or where to see its variants or report, its state and what the user must do next; the items dropped or queued, and why; and the decisions made for the user.
