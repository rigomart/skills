---
name: comments
description: Cut the comments a change adds or edits down to the ones that earn their place, and make those short. A fresh subagent that did not write them checks the diff against a closed keep list; you apply its findings, turn surprises in our own code into renames or extractions, and offer to encode true constraint comments as types, tests or checks. Use before committing or opening a PR, when asked to review, trim or clean up comments, or when a diff carries narration, banners or commented-out code.
---

# Comments

A comment earns its place only when it says something the code cannot: a reason forced from outside, a public contract, a license. Everything else is noise that drifts out of date. The agent that wrote a comment defends it, so the judging goes to a checker that did not write it, and you apply what survives your check.

## 1. Scope

The comments the change added or edited: the caller's files or diff, or else everything the branch changes against the default branch: `git diff $(git merge-base HEAD origin/<default>)` for tracked files, working tree included, plus the new files `git ls-files --others --exclude-standard` lists, every line of which is added. Comments on lines the change did not touch stay out, except one the change made false.

## 2. Check

Spawn one read-only Checker subagent, with its model set by the `model-roles` skill (your session's model if that skill is not installed). Its prompt is [references/checker.md](references/checker.md), verbatim, followed by the scope: the repo path, the base ref, and the file list with new untracked files marked as new.

Without a subagent tool, apply `references/checker.md` yourself, comment by comment, and say in the report that no independent checker ran.

## 3. Verify the findings

Read `references/checker.md` so you judge by the same rules. Then go through every finding:

- **Reject** a finding outside the scope, one that deletes something on the keep list, one that changes code that is not a comment, and one whose reason misstates the comment or the code.
- **Verify constraint claims.** For each `encode` finding, read the code the comment guards and confirm the claim is true today. A false claim becomes a `delete`.
- **Look for misses.** Skim the scoped diff for comments the checker passed over, lint suppressions especially, and judge them by the same rules.

If more than a few findings fail the check, rerun the checker once with the failures named. If its second report fails too, apply the findings that passed and report the rest as open.

## 4. Apply

- `delete` and `tighten`: make the edit exactly as given.
- `reshape`: the comment explained a surprise in our own code. Delete the comment and make the code say it, with the smallest in-scope change: rename a variable or function, extract a named constant or helper, narrow a type. When the fix needs more than that (a new boundary, a change outside the scope), delete the comment anyway and report the reshape as open.
- `reshape` on a lint or type suppression: fix the code so the rule passes, or leave the suppression and report the reshape as open. A cast is not a fix: turning `as any` into `as Rate` hides the same unchecked data. When the real fix changes behavior (validating input that was trusted), it is the user's call, so leave it open.
- `encode`: the comment states a true constraint (`do not remove`, `must run before X`). Offer the cheapest in-scope encoding: a type, an assertion, a test, a lint rule. Encode it once the user approves, then delete the comment. Until then the comment stays, tightened to the constraint alone.
- `todo`: a TODO with no issue link. Delete it and list it in the report so the user can file it.

Run the project's lint, typecheck and tests if a reshape changed code.

## 5. Report

Counts of comments deleted, tightened and kept; each reshape applied, with its file and symbol; reshapes and encodings left open, one line each; TODOs removed; rejected findings and why; and whether an independent checker ran.
