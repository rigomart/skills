# Fleet

You own the queue: what runs, when, and what reaches the user. Each item's owner, a subagent, owns its change, its proof and its PR. The user owns decisions and merges.

1. List the items, each one change that ships as its own PR. When a ledger for this work exists (see **Ledger**), resume from it and `gh pr list` instead. Read each issue with its comments. Drop an item a merged PR or a commit on the default branch already covers, and say which: search merged PRs and `git log origin/<default>` by the issue's symptom and the files it names, since a fix often never names its issue. Two items that would edit the same lines, or where one builds on the other, go to one owner as one PR, or the second waits for the first to merge. Items that only share a file, each adding its own line to a router or its own test to a test file, run at once: the second to merge resolves a one-line conflict. An item the `build` playbook would prototype leaves the fleet: name it for the user to run with `/do build`. Done when every item is kept, joined to another, queued behind one, or dropped with a reason.
2. Write the ledger. From here on, update it on every event before you reply, and answer status questions from it, not from memory.
3. Ask once, numbered, recommendation first, every question the `implement` skill says to ask, across all items. Items no answer blocks don't wait for it.
4. Fetch, then start one owner per item, each in its own worktree from the latest default branch, with the **Owner brief** and the role and model the `subagents` skill gives it (Implementer or Engineer). Start each wave at once, within that skill's limits on agents running at once.
5. When an owner reports, check its PR is at the head it names (`gh pr view <n> --json headRefOid,files`) and spot-check one claim against its evidence. Update the ledger, watch the PR with the `babysit-pr` skill, and start the next queued item. An owner that couldn't run its review: spawn a Reviewer (`subagents` skill) on its branch's diff with the item and the owner's evidence, and send the owner the findings. An owner's question goes to the user with any others pending, and the answer goes back to that owner. Edit, rebase and push nothing of an owner's yourself: everything its PR needs goes back to its owner, continued with its context. When it can't be continued, start a fresh owner on its branch with the original brief and what's new.
6. When a PR's checks or state change, handle it with the `babysit-pr` skill. When a PR merges, check the other open ones for a conflict or a stale base, and send each conflict to its owner.
7. Message the user only when an answer is needed, a PR is green and ready for their review, or every item is done, each time with the ledger as one line per item. An event that changes nothing for them gets no message.
8. Stop when every item is merged, closed, or green and waiting on the user's review, and stop watching every PR.

## Ledger

`.evidence/<fleet>/ledger.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints. One row per item:

| Item | Owner | PR | State | Next | Needs you |
| --- | --- | --- | --- | --- | --- |
| #12 export fails on an empty list | how to reach the owner (its id or thread) | #40 | checks green | user review | merge; nothing before |

State is one of: queued, building, waiting on an answer, PR open, checks failing, ready for review, merged, moved out (to `/do build`), dropped. A new session resumes from this file, so it carries everything the work needs that the PRs don't: settled decisions, items queued behind others, why an item was dropped.

## Owner brief

Fill in each `<...>`:

```text
<The item as a user would ask for it: "Fix #12 (<url>) and open a PR against <default>.">

Follow the build playbook at <absolute path of this folder>/build.md. You may spawn the subagents it calls for.

Settled: <the user's answers and the decisions already made, or "none">. Other owners are changing <their files or areas> at the same time: <how to stay out of their way>.

Run one build or test command at a time, and stop every process you started before you report.
```

**Reply:** the ledger as one line per item, each with its PR link, its state and what the user must do before merging; the items dropped or queued, and why; and the decisions made for the user.
