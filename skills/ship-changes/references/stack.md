# Stacks

## Shape

Every PR in a stack must be safe to merge and deploy alone. When merging to `main` deploys, a migration goes in a lower PR than the code that needs it, and no PR may depend on one above it. If migrations are numbered, only one stack at a time adds one, or the numbers collide.

A stack is a chain of base branches. The bottom PR targets `main`; each PR above it is branched from the tip of the one below and targets it:

```bash
git switch -c <child-branch> <parent-branch>
# commit the child's work
git push -u origin <child-branch>
gh pr create --base <parent-branch> --title "..." --body-file <body.md>
```

## Opening

Open the whole stack before landing any of it.

- Verify each PR at its own head, and take its screenshots there.
- Each PR takes the template for its own title's type. Its body's first line names its place: `Part 2 of 3. Builds on #456.`
- When the `link_pull_request` tool is available, link every layer.

## Landing

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
