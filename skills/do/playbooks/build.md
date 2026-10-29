# Build

You own the change and its proof. The user owns the direction.

1. Load the `implement` skill and settle the request's decisions the way it says.
2. Decide whether to prototype, and write the call as one line: `Prototype: yes|no, because <the case below>`. Make the call again on each new message from the user.
   - **No** when the request says what the result should be ("move the filters to a sidebar", "add a `--json` flag"), comes with a mock, screenshot, spec or acceptance criteria, follows a pattern the app already has, fixes a bug, or is judged by a number (speed, size, a passing test).
   - **Yes** when none of those fit and the request names a problem with how something looks or is used but not the fix ("looks terrible", "feels cluttered", "redesign this", "still not right"), or asks for options or directions.
   - **Neither**: no.

   On yes, run the `prototype` skill and stop for the user's pick. Build the pick from the commit that keeps the other variants; the real build replaces the prototype code for that surface.
3. Capture the before evidence, as `implement` describes under **Prove it**.
4. Build the change within `implement`'s **Scope**. Work across several subsystems, or with heavy research, runs through the `orchestrate` skill.
5. Capture the after evidence and run what CI runs.
6. Review round 1 of 3. Spawn a Reviewer (`model-roles` skill) on the diff with the request and your evidence, and no hint of the verdict you expect. Fix each finding that holds up when you check it, and note why you dismissed the rest. A change you can check in one read (a one-liner, a rename, copy) skips review.
7. Review round 2 of 3, only when round 1 led to fixes. A fresh Reviewer gets the original brief, the earlier findings, your response to each and any objection still open. It checks the fixes and reopens nothing already settled.
8. Review round 3 of 3, only when round 2 led to fixes, built the same way. Findings still open after it go under **Not done**.
9. When review changed code, rerun the checks from step 5.
10. Stop. Ship only when the request asked for it, with the `ship-changes` skill, then babysit the PR to green with the `babysit-pr` skill.

**Reply:** `implement`'s **Report**, then `babysit-pr`'s reply when you shipped. After a prototype round, the `prototype` skill's reply instead.
