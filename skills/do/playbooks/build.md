# Build

You own the change and its proof.

1. Load the `implement` skill and settle the request's decisions the way it says. When several plausible behaviors stay open, run the `prototype` skill and stop for the user's pick.
2. Capture the before evidence, as `implement` describes under **Prove it**.
3. Build the change within `implement`'s **Scope**. Work across several subsystems, or with heavy research, runs through the `orchestrate` skill.
4. Capture the after evidence and run what CI runs.
5. Review round 1 of 3. Spawn a Reviewer (`model-roles` skill) on the diff with the request and your evidence, and no hint of the verdict you expect. Fix each finding that holds up when you check it, and note why you dismissed the rest. A change you can check in one read (a one-liner, a rename, copy) skips review.
6. Review round 2 of 3, only when round 1 led to fixes. A fresh Reviewer gets the original brief, the earlier findings, your response to each and any objection still open. It checks the fixes and reopens nothing already settled.
7. Review round 3 of 3, only when round 2 led to fixes, built the same way. Findings still open after it go under **Not done**.
8. When review changed code, rerun the checks from step 4.
9. Stop. Ship only when the request asked for it, with the `ship-changes` skill.

**Reply:** `implement`'s **Report**.
