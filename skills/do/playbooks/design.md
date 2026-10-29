# Design

You own the look and feel. The user owns the direction.

1. Capture the before: a screenshot of every screen and state the request touches, with the project's `verify-<app>` skill when it has one.
2. Settle the direction. When the request leaves several plausible looks, or the user is still unhappy after a second try, run the `prototype` skill and stop for the user's pick. When the request already says what to change, skip: the direction is set.
3. Build the picked direction with the `implement` skill. After a prototype, start from the commit that keeps the other variants; the real build replaces the prototype code for that surface.
4. Capture the after: the same screens and states as step 1, at the same sizes.
5. Check each after image against the request yourself before showing it: empty space, overflow, alignment, contrast in each theme. Fix what you find and capture again.
6. Finish as in the `build` playbook's steps 5 to 9, on the code diff: its review rounds, its checks, and shipping only when asked.

**Reply:** the before and after images side by side, then the `build` playbook's **Reply**. After a prototype round, the prototype's own reply instead.
