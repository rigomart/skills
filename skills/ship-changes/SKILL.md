---
name: ship-changes
description: Packages current repository changes into a branch, commit or commits, push, and pull request using the project's conventions, splits work into a stack of PRs when it has natural seams, and lands PRs or stacks through GitHub auto-merge. Use when the user asks to ship changes, create a branch, commit, push, open a PR or a stack, merge or land a PR, or prepare work for review.
---

# Ship Changes

## Read the project first

Before shipping, learn the project's own rules and follow them over the defaults here:

- `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`: commit style, PR rules, required checks, anything they ask you to surface in a PR.
- `git log --oneline -20`: the commit convention actually in use.
- The CI workflows (`.github/workflows/*.yml` or the project's CI config): the commands a PR must pass.
- The default branch: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. This skill calls it `main`.

## Branch Naming

Branch names should be short, lowercase, hyphenated, and based on the actual change. If an issue number is central, include it after the topic, not as the whole name.

```text
items-inline-editing
fix-inbox-count-optimism
docs-agent-dev-server-rules
items-inline-editing-135
```

Never use:

```text
codex/*
codex-*
work
changes
issue-123
```

## Branch Creation

First inspect the current branch and worktree state:

```bash
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

When working in a worktree, do not assume the branch should be based on `main`. Treat the checked-out worktree branch as the base unless the user explicitly asks to rebase, retarget, or start over from `main`.

Part of the branch may already have landed through a squash merge, which `git log origin/main..HEAD` still lists. Check each commit ahead of `main` with `gh pr list --state merged --search <sha>`. When the lower ones already merged, put only the rest on a new descriptive branch from `origin/main` with `git rebase --onto origin/main <last-merged-sha> <new-branch>`, and leave the worktree's branch as it is.

If the current branch is already a descriptive feature branch for the work being shipped, keep using it. If the current branch is `main`, `master`, a branch an agent tool named for itself (`codex/*`, `codex-*`, `t3code/*`, `claude/*`), or a generic branch name, create a new descriptive branch from the current `HEAD`:

```bash
git switch -c <descriptive-branch-name>
```

Do not move, reset, or recreate the worktree from `main` just to make a shipping branch. Only change the base when the user asks or when the current branch clearly cannot be pushed or used for a PR.

## Commit Strategy

Use one commit when the changes form one coherent feature or fix. Use multiple commits when changes are independently reviewable, such as production code plus a docs-only policy change, a refactor before a feature, or unrelated fixes discovered during the work.

Every commit uses the project's commit style. When the project has none, use Conventional Commits. Before committing, confirm the staged diff only contains intended files.

```text
feat(items): add inline item editing
fix(inbox): keep optimistic count in sync
docs(agents): document local dev server policy
refactor(items): extract date update hook
```

## One PR or a Stack

Default to one PR. Split into a stack only when the work has a seam a reviewer would review separately, and each piece is useful on its own:

- a migration, then the API that uses it, then the UI
- a refactor, then the feature it makes room for
- a contract change, then its callers

Every PR in a stack must be safe to merge and deploy alone. When merging to `main` deploys, a migration goes in a lower PR than the code that needs it, and no PR may depend on one above it. If migrations are numbered, only one stack at a time adds one, or the numbers collide.

A stack is a chain of base branches. The bottom PR targets `main`; each PR above it is branched from the tip of the one below and targets it:

```bash
git switch -c <child-branch> <parent-branch>
# commit the child's work
git push -u origin <child-branch>
gh pr create --base <parent-branch> --title "..." --body-file <body.md>
```

Open the whole stack before landing any of it. In each PR body, name its place: `Part 2 of 3. Builds on #456.`

## Verification

Before committing, run the `comments` skill on the diff if it is installed, alongside any review the project runs before a commit.

Before pushing, run what CI runs: the lint, format, typecheck, build, and test commands from the CI workflows, through the project's package scripts or task runner. Run each one CI runs separately. A build that skips tests does not prove they type-check.

A user-visible change also needs proof in the real app. If the project has a verification skill or documented way to drive the app, use it. Lint and tests don't substitute for it. In a stack, verify each PR at its own head.

## PR Format

Use a conventional PR title matching the main commit or the overall change.

```text
feat(items): add inline item editing
```

The body is a briefing for a reviewer who has the diff: why the change exists, what it leaves out, and how it was proven. Use these sections in order and drop any that has nothing to say:

```md
## Why
One or two short paragraphs: the problem and the approach.

## Scope
- Real symbols and paths that carry the change
- What is deliberately left out, when the boundary matters

## Tradeoffs
Alternatives a reviewer would ask about, and why not.

## Blast radius
One to three sentences: what this touches, what could go wrong, and how it would show up.

## Verification
- The CI commands you ran locally
- How the change was driven in the real app, and what it showed

## Screenshots
| Before | After |
| --- | --- |
| ![Inbox badge shows 3 after archiving one of 3](./.verify/main/evidence/inbox-badge-before.png) | ![Inbox badge shows 2 after archiving one of 3](./.verify/main/evidence/inbox-badge-after.png) |

Closes #123
```

`Blast radius` and `Tradeoffs` are where compromises go, including any the project's agent instructions ask you to surface. Don't write `## Summary` or `## Test plan` boilerplate, file-by-file lists, or SHAs. If a command was not run, say why instead of listing it.

### Screenshots

A change a user can see carries images in its PR: UI, layout, styling, copy, icons, an app's or a TUI's screens. CLI output goes in a text block of the real output instead, which a reviewer can search and diff.

- **Take them from the verification run** at the PR's head. When the project's verification skill names the images meant for the PR, use those. When it names none, or there is no such skill, take them while driving the change: one per changed state and per variant (width, theme), cropped to the change. When the change alters an existing screen, add a before image of the same state: revert the change's files in the working tree (`git checkout origin/<base> -- <files>`), take it, restore them (`git checkout HEAD -- <files>`), and confirm `git status` is clean. A recording replaces stills when the sequence is the change (focus moving, an animation).
- **Look at each image before attaching it.** Attaching publishes it. It shows the app with throwaway data only, nothing from the developer's own account or the rest of their screen.
- **Alt text says what the image proves**, not what it is: `Inbox badge shows 2 after archiving one of 3`, not `screenshot`.
- **Attach with `gh`.** `gh pr create`, `gh pr edit` and `gh pr comment` take `--attach <file>`, up to 50 per command. Run the command from the repo root, and reference each file in the body by exactly the path you pass to `--attach` (`./.verify/…`); the body file itself can live anywhere. `gh` uploads each file and rewrites the reference to the hosted asset. An attached file the body does not reference is appended to the end.

  ```bash
  gh pr create --title "..." --body-file body.md \
    --attach ./.verify/main/evidence/inbox-badge-before.png \
    --attach ./.verify/main/evidence/inbox-badge-after.png
  ```

  If some uploads fail, `gh` still creates the PR with the rest and exits non-zero; reattach the missing ones with `gh pr edit <pr> --attach`.
- **Keep them current.** When a later push changes what the screen shows, retake the images and replace the body with `gh pr edit <pr> --body-file body.md --attach …`, so the PR never shows a stale state.
- **No `--attach`** in `gh <cmd> --help` means an older `gh`. Propose upgrading it; that is the user's call. Until then, open the PR without the section and tell the user which images to drag into it.

In a stack, each PR attaches the images from its own head.

The PR body must reference the issue it closes when the work is tied to an issue. Look for the issue number in the session context, the user's request, branch name, commit messages, recent issue discussion, or the diff itself.

Use GitHub closing syntax, such as `Closes #123`, so merging the PR closes the issue automatically. If an issue appears relevant but cannot be identified, ask the user before creating the PR instead of guessing. If the change is clearly not issue-backed, such as a small agent-instruction cleanup requested directly in chat, omit the closing line and continue creating the PR.

Open every PR ready for review, never as a draft. When the `link_pull_request` tool is available, link every PR you open, each layer of a stack included.

## Landing

Opening a PR does not merge it. Land only when the user asks to merge, land, or ship it.

There is no babysitting loop. GitHub auto-merge waits for CI and merges, and squash-merging deletes the branch:

```bash
gh pr merge <pr> --squash --auto
```

Auto-merge needs the repository to allow it and `main` to have required checks. Without required checks, `--auto` merges at once, before CI finishes. If auto-merge is off or `main` has no required checks, say so and ask before merging another way. If the repository does not allow squash merges, use the method it allows; the stack recipe below assumes squash.

Then do one background wait, so a failure in your own diff gets fixed while the context is fresh:

```bash
gh pr checks <pr> --watch --fail-fast
```

If it fails, read `gh run view <run-id> --log-failed`. Fix a failure in the diff's own code with one push; auto-merge stays armed. If the failure is in code the diff doesn't touch, check whether the branch is behind `main` before blaming flake, and rerun a flaky job at most once. Anything else, report and stop. A red PR stays open and visible on GitHub, so walking away is safe.

### Landing a stack

Arm auto-merge on the bottom PR only. Required checks usually guard only `main`, so a PR that targets another branch has none, and arming it merges it into its parent at once, collapsing the stack.

When the bottom PR merges, GitHub deletes its branch and retargets the next PR to `main`. That PR still carries the parent's original commits, which `main` now holds as one squash commit, so replay only its own commits:

```bash
git fetch origin
git rebase --onto origin/main <old-parent-tip-sha> <child-branch>
git push --force-with-lease
gh pr merge <child-pr> --squash --auto
```

`<old-parent-tip-sha>` is the parent branch's last commit, which `gh pr view <parent-pr> --json headRefOid` still reports after the merge. If the rebase hit conflicts, re-run verification on the child before arming it. Repeat up the stack, one PR at a time.

## Workflow

1. Read the project's rules, then check branch and worktree state with `git status --short`, `git diff --stat`, and targeted diffs.
2. Summarize what will ship: one commit or several, one PR or a stack.
3. Decide whether to keep the current branch or create a descriptive branch from the current worktree `HEAD`.
4. Run the `comments` skill and verification. Stage only intended files, commit in the project's style, and push.
5. Create the PR or the stack with the standard title and body, attaching the screenshots when the change is visible and including the closing issue reference when the work is issue-backed, and link each PR.
6. If the user asked to land, arm auto-merge as described in Landing.
7. Final response includes branch, commit hash or hashes, PR link or links, verification status, the images attached or why there are none for a visible change, and whether auto-merge is armed.
