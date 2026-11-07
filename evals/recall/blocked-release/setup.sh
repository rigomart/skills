# Release 0.4.0 (#18): #16 and #17 merged; release PR #21 is open and its
# npm-auth check fails with E401 on every commit. A past chat from 6 days ago hit
# the same E401 on 0.3.1 and cleared it: the user made a new granular npm token
# with a short expiry and set it with `gh secret set NPM_TOKEN`. A chat from
# yesterday opened #21 and saw the E401 again.
source "$EVAL_HERE/recall/lib.sh"
recall_repo '{"npm-auth": "echo \"npm error code E401\"; echo \"npm error 401 Unauthorized - GET https://registry.npmjs.org/-/whoami\"; echo \"npm error Unable to authenticate, your authentication token seems to be invalid.\"; exit 1"}'
gh_json '.ci.step_names = {"npm-auth": "npm whoami"}'
cd "$REPO"
cat >> .github/workflows/ci.yml <<'YML'
  npm-auth:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with: { node-version: 24, registry-url: "https://registry.npmjs.org" }
      - run: npm whoami
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
YML
cat > .github/workflows/release.yml <<'YML'
name: Release
on:
  push:
    tags: ["v*"]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, registry-url: "https://registry.npmjs.org" }
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
YML
commit_push "ci: check the npm token and publish on tags"
git tag v0.3.0; git push -q origin v0.3.0 2>/dev/null
at 6; perl -pi -e 's/"version": "0.3.0"/"version": "0.3.1"/' package.json; commit_push "chore(release): 0.3.1 (#15)"
git tag v0.3.1; git push -q origin v0.3.1 2>/dev/null
at 4; change_list_json; commit_push "feat(list): add --json output (#16)"
at 3; change_due_dates us; commit_push "feat(add): accept a due date (#17)"
at 1; git switch -q -c release-0.4.0
perl -pi -e 's/"version": "0.3.1"/"version": "0.4.0"/' package.json
printf '# Changelog\n\n## 0.4.0\n\n- `tasks list --json` (#16)\n- Due dates on tasks (#17)\n' > CHANGELOG.md
commit_push "chore(release): 0.4.0"
git switch -q main

pr 15 release-0.3.1 MERGED "chore(release): 0.3.1" "Fixes the store path on Windows."
pr 16 list-json MERGED "feat(list): add --json output" "Part of #18."
pr 17 due-dates MERGED "feat(add): accept a due date" "Part of #18."
pr 21 release-0.4.0 OPEN "chore(release): 0.4.0" "Release 0.4.0, #18. Bumps the version and adds the changelog. Merging it and tagging v0.4.0 publishes to npm."
gh_json '.issues = {"18": {title: "Release 0.4.0", state: "OPEN",
  body: "- [x] `tasks list --json` (#16)\n- [x] Due dates (#17)\n- [ ] Merge the release PR and tag v0.4.0, which publishes to npm"}}
  | .releases = [
    {tagName: "v0.3.1", name: "v0.3.1", publishedAt: "2026-11-01T16:00:00Z", isLatest: true, body: "Fixes the store path on Windows (#15)."},
    {tagName: "v0.3.0", name: "v0.3.0", publishedAt: "2026-10-18T10:00:00Z", isLatest: false, body: "First release."}]'

recall_isolate
claude_session 6 7d2e9a10-release-031 <<'CHAT'
U Ship 0.3.1, the fix for the store path on Windows.
A PR #15 is green except npm-auth, which fails with npm error code E401: the registry rejects the NPM_TOKEN secret. I can't fix that from here.
U The old token was a classic one and npm turned those off. I made a granular access token on npmjs.com with read and write on the tasks package, set to expire in a week, and ran gh secret set NPM_TOKEN. Rerun it.
A Reran npm-auth on #15 and it passes now. Merged #15, tagged v0.3.1, and the release workflow published 0.3.1.
U Good. Next time give the token a longer expiry.
CHAT
codex_session 1 2026-11-06T09-30-release-040 <<'CHAT'
U Start the 0.4.0 release, #18.
A Opened #21 with the version bump and a changelog. lint and test pass; npm-auth fails with E401 again.
U Leave it, I'll look at it later.
CHAT
snapshot
