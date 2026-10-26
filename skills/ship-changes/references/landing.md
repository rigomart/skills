# Landing

There is no babysitting loop. GitHub auto-merge waits for CI and merges, and squash-merging deletes the branch:

```bash
gh pr merge <pr> --squash --auto
```

Auto-merge needs the repository to allow it and `main` to have required checks. Without required checks, `--auto` merges at once, before CI finishes. If auto-merge is off or `main` has no required checks, say so and ask before merging another way. If the repository does not allow squash merges, use the method it allows; the stack recipe in [stack.md](stack.md) assumes squash.

Then do one background wait, so a failure in your own diff gets fixed while the context is fresh:

```bash
gh pr checks <pr> --watch --fail-fast
```

If it fails, read `gh run view <run-id> --log-failed`. Fix a failure in the diff's own code with one push; auto-merge stays armed. If the failure is in code the diff doesn't touch, check whether the branch is behind `main` before blaming flake, and rerun a flaky job at most once. Anything else, report and stop. A red PR stays open and visible on GitHub, so walking away is safe.
