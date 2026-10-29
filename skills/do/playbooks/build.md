# Build

You own the change and its proof. The user owns the direction.

1. Load the `implement` skill and settle the request's decisions the way it says.
2. Decide whether to prototype by the cases below, and fold the call into the opening sentence, without the reason: `Using the build playbook, no prototype.` Make the call again on each new message from the user, and say it only when it changes.
   - **No** when the request says what the result should be ("move the filters to a sidebar", "add a `--json` flag"), comes with a mock, screenshot, spec or acceptance criteria, follows a pattern the app already has, fixes a bug, or is judged by a number (speed, size, a passing test).
   - **Yes** when none of those fit and the request names a problem with how something looks or is used but not the fix ("looks terrible", "feels cluttered", "redesign this", "still not right"), or asks for options or directions.
   - **Neither**: no.

   On yes, run the `prototype` skill and stop for the user's pick. Build the pick on a new branch from the default branch, never on top of the prototype branch, so no prototype code reaches the PR. The prototype branch keeps the other variants until you ship.
3. Capture the before evidence, as `implement` describes under **Prove it**.
4. Build the change within `implement`'s **Scope**. Work across several subsystems, or with heavy research, runs through the `orchestrate` skill.
5. Capture the after evidence and run what CI runs.
6. Review round 1 of 2. Spawn a Reviewer (`model-roles` skill) on the diff with the request and your evidence, and no hint of the verdict you expect. Fix each finding that holds up when you check it, or put it under **Not done** with why, and drop the ones that don't. A change you can check in one read (a one-liner, a rename, copy) skips review.
7. Review round 2 of 2. Check each fix from round 1 yourself. Spawn a fresh Reviewer only when a fix is too big to check in one read: it gets the original brief, the earlier findings, your response to each and any objection still open, checks the fixes and reopens nothing already settled. Findings still open after it go under **Not done**.
8. When review changed code, rerun the checks from step 5.
9. Stop. Ship only when the request asked for it, with the `ship-changes` skill. Once the PR is open, delete the prototype branch the pick came from, locally and on the remote, and name it in the reply. Then babysit the PR to green with the `babysit-pr` skill.

**Reply:** `implement`'s **Report**, then `babysit-pr`'s reply when you shipped. After a prototype round, the `prototype` skill's reply instead.
