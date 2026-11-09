# Stacks

## Shape

Every PR in a stack must be safe to merge and deploy alone. When merging to `main` deploys, a migration goes in a lower PR than the code that needs it, and no PR may depend on one above it. If migrations are numbered, only one stack at a time adds one, or the numbers collide.

A stack is a chain of branches. The bottom PR targets `main`; each PR above it is branched from the tip of the one below and targets it.

## Native or manual

Ship every stack as a GitHub stacked PR chain unless that can't be done. GitHub then runs `main`'s checks and rules on every PR in it, and when a lower PR merges, it retargets and rebases the rest itself.

Before opening or landing a stack, run [../scripts/stack-ready](../scripts/stack-ready) by its absolute path. It installs the `github/gh-stack` extension when `gh` has no `stack` command, and prints one line:

- `native: ...`, exit 0: follow **Native stack**.
- `manual: <reason>`, exit 1: follow **Manual chain**, and put its reason in the report.
- exit 2: say what its line says, and stop.

When the repository has more than one remote, pass `--remote <the remote you push to>` to every `gh stack` command that takes it.

## Native stack

### Opening

Open the whole stack before landing any of it. Build each branch from the tip of the one below, commit its work, then adopt the branches into a local stack, bottom first, and push them:

```bash
git switch -c <child-branch> <parent-branch>
# commit the child's work
gh stack init <bottom-branch> <next-branch> ...
gh stack push
```

Verify each PR at its own head, and take its screenshots there. Each PR takes the template for its own title's type, and its body's first line names its place: `Part 2 of 3. Builds on #456.` Create the PRs bottom first, each against the branch below it, then link them into a stack in the same order:

```bash
gh pr create --head <branch> --base <parent-branch> --title "..." --body-file <body.md>
gh stack link <bottom-branch> <next-branch> ...
```

Create each PR with `gh pr create` and your own title and body. `gh stack submit` and `gh stack link` create any missing PR as a draft with a generated title. When `link` exits 9, stacked PRs are off after all: the PRs are already chained by their bases, so land them as **Manual chain** says.

Run `gh stack` commands with every argument they need, and read the stack with `gh stack view --json`. Bare `gh stack view`, `submit`, `init`, `add`, `checkout` and `modify` open prompts or full-screen views that never return in an agent's shell.

### Fixes after opening

Commit a fix on the branch whose layer owns the change, then replay the branches above it and push them all:

```bash
gh stack rebase --no-trunk
gh stack push
```

GitHub merges only a linear stack: a PR whose branch no longer holds its parent's tip can't merge until this runs.

### Landing

Follow [landing.md](landing.md) for the CI wait, with these differences.

GitHub can't arm auto-merge on a stacked PR. Merge it yourself once the `babysit-pr` skill reports green every PR you land. To land the whole stack, merge its top PR; to land part of it, the highest PR of that part. That PR and every unmerged PR below it merge in one step, and none of them merge if one is blocked:

```bash
gh stack merge <highest-pr-to-land> --yes --squash
```

When the merge fails because the stack isn't linear, run the two commands in **Fixes after opening** and wait for green again. Use the repository's allowed method in place of `--squash` when it has no squash merge; `can-auto-merge` prints the allowed ones. After a partial landing, GitHub retargets the next PR to `main` and rebases the rest; run `gh stack sync --prune` before working on them locally.

## Manual chain

### Opening

As **Native stack** says, except that each branch is pushed on its own and nothing links the PRs:

```bash
git switch -c <child-branch> <parent-branch>
# commit the child's work
git push -u origin <child-branch>
gh pr create --base <parent-branch> --title "..." --body-file <body.md>
```

### Landing

Follow [landing.md](landing.md) for auto-merge and the CI wait, with these differences.

Arm auto-merge on the bottom PR only. Required checks usually guard only `main`, so a PR that targets another branch has none, and arming it merges it into its parent at once, collapsing the stack.

When the bottom PR merges, GitHub deletes its branch and retargets the next PR to `main`. That PR still carries the parent's original commits, which `main` now holds as one squash commit, so replay only its own commits:

```bash
git fetch origin
git rebase --onto origin/main <old-parent-tip-sha> <child-branch>
git push --force-with-lease
gh pr merge <child-pr> --squash --auto
```

`<old-parent-tip-sha>` is the parent branch's last commit, which `gh pr view <parent-pr> --json headRefOid` still reports after the merge. If the rebase hit conflicts, re-run verification on the child before arming it. Repeat up the stack, one PR at a time.

## A branch that partly landed

A squash merge leaves the merged commits in `git log origin/main..HEAD`. Check each commit ahead of `main` with `gh pr list --state merged --search <sha>`. When the lower ones already merged, put only the rest on a new descriptive branch from `origin/main` with `git rebase --onto origin/main <last-merged-sha> <new-branch>`, and leave the worktree's branch as it is.
