---
name: babysit-pr
description: Watch a pull request until its checks pass, fix the failures its own diff caused, and hand it back for review. Use when asked to babysit, watch or monitor a PR, or to get it green.
---

# Babysit PR

A PR is done when its checks are green on the latest head and it does not conflict with its base. The user owns the merge: they review the final diff on GitHub, so a green PR goes back to them with its link. Merging goes through the `ship-changes` skill.

## Find the PR

Take the number or URL the user gave, else the PR for the current branch: `gh pr view --json number,url,headRefOid,state`. Fixes need the PR's branch checked out in a clean tree: `gh pr checkout <pr>`.

One watcher per PR. When you are a delegated child (a reviewer, a `delegate_task` or subagent run), report back to the parent instead: the parent owns the PR and watches it.

Done when you have the PR number, and its head is the commit you expect (`git rev-parse HEAD` after your last push).

## Wait

Write no sleep or polling loop of your own. Start a new wait after every push.

- **In T3 Code** (the `watch_pull_request` tool exists): call it and end your turn. It wakes you when a check fails, the required checks pass, someone comments or reviews, or the branch conflicts. A wake is news, not a verdict: read the checks yourself with `gh pr checks <pr>`. A wake that needs nothing from you, such as a review comment, ends your turn with no message; the watch stays on.
- **Everywhere else**: run [scripts/wait-green](scripts/wait-green) by its absolute path, as one background command (`run_in_background` in Claude Code). It waits for checks to register on the head, watches them, and prints one line:

| Exit | Line | Next |
| --- | --- | --- |
| 0 | `green on <sha>` with the check counts, how many commits it is behind its base, and the merge state; or `merged` | **Hand back** |
| 1 | `check failed` with each failed check's link, a conflict with the base, or `closed` | **Handle a failure**, or **Hand back** for a closed PR |
| 2 | bad input, or no checks registered within 5 minutes | tell the user the PR has no CI to watch, and stop |

`watch_pull_request` reports conflicts but not a branch that is behind its base, and `mergeStateStatus` says `BEHIND` only when nothing else blocks the merge. Count it yourself, with the head SHA so a fork's branch resolves:

```bash
gh api 'repos/{owner}/{repo}/compare/<base>...<head-sha>' --jq .behind_by
```

## Handle a failure

Read the failed log before acting: `gh run view <run-id> --log-failed`, with the run id from the check's link. When GitHub answers `HTTP 410`, the log has expired: rerun the failed jobs with `gh run rerun <run-id> --failed` to get a fresh one, which does not count as a flake rerun. Then classify the failure:

| The failure | Action |
| --- | --- |
| Code or config this PR changes | Fix it, run the failing check locally, push one commit with every fix you know of, and wait again. |
| Code this PR does not touch, while the branch is behind its base (**Wait** says how to count it) and the check passes on the base | Stale base. Update with `gh pr update-branch <pr>`, which merges the base in without a force-push, and wait again. In a stack, report it instead. |
| A conflict with the base that keeping both sides resolves: neighboring imports, entries added to the same list, a lockfile | Merge the base in (`git merge origin/<base>` after a `git fetch`), keep both sides, regenerate a lockfile with the package manager, run the checks the conflicted files touch, push without force, and wait again. In a stack, report it instead. |
| A flake or the infrastructure: a lost runner, a network error, a timeout, a test that passes locally and on the base | `gh run rerun <run-id> --failed`, once per check. A second identical failure is not a flake: classify it again. |
| Anything else: the base fails the same way, a missing secret or permission, a conflict that needs a choice between the two sides | Report it. |

Keep each fix to what the failing check needs. A fix that would grow the PR past its goal goes in the report as a follow-up. Three pushes that each fail anew mean the cause is not one you can see from the diff: report it.

When another agent owns the branch, it makes the fixes: send it each one with the failed run's link, and push nothing to its branch yourself.

## Hand back

Hand back when the PR is done, when a failure is one to report, or when the PR merges or closes. In T3 Code, call `unwatch_pull_request` before you reply, so the thread returns to the user's inbox.

Review comments and reviews are not part of babysitting. List the ones that arrived, and act on them only when the user asks.

**Reply:** the PR link and its state (`green on <sha>, ready for your review`, or what blocks it), the checks' result, each fix pushed with the failure it fixed, each rerun and why, review comments that arrived, and whether the branch is behind its base.
