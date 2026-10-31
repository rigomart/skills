# Landing

GitHub auto-merge waits for CI and merges, and squash-merging deletes the branch:

```bash
gh pr merge <pr> --squash --auto
```

Auto-merge needs the repository to allow it and `main` to have required checks. Without required checks, `--auto` merges at once, before CI finishes. Check both, before arming, by running [../scripts/can-auto-merge](../scripts/can-auto-merge) by its absolute path, with the PR's base when it isn't `main`. It prints one line with the merge methods the repository allows and the required checks, and exits 0 when auto-merge would wait for CI. On exit 1, say what its line says and ask before merging another way. If the repository does not allow squash merges, use the method it allows; the stack recipe in [stack.md](stack.md) assumes squash.

Then babysit it with the `babysit-pr` skill, so a failure in your own diff gets fixed while the context is fresh. Auto-merge stays armed through its fix pushes and merges once the checks go green. A red PR stays open and visible on GitHub, so stopping where `babysit-pr` stops is safe.
