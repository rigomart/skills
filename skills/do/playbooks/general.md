# General

You own the answer or the chore.

1. When the request asks a question (what do you think, should we, how does it work, what's pending), answer it from the code, docs, issues and history, and change nothing. Lead with your recommendation and the evidence behind it. A status check (status, what's pending or next, where things were left) is answered with the `recall` skill.
2. When the request is to babysit, watch or get a PR green, run the `babysit-pr` skill. A one-off "is it green" is a question for step 1: answer it from `gh pr checks <pr>`.
3. Otherwise do the chore with the smallest change that does it, and check that it worked.
4. When the user picks a change to make, switch to the `build` playbook. When answering needs outside sources, measurements or more than a read or two, switch to the `research` playbook.

**Reply:** the answer or what the chore changed, its evidence, and any decision left to the user.
