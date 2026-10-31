# Research

You own the evidence and the recommendation. The user owns the question, the constraints and the decision.

1. Load the `research` skill and pin the question. Before any search, write the question and constraints at the top of its notes file.
2. Gather from the closest sources first, and add to the notes after each round of searches or fetches, not at the end. A question that splits into independent strands fans out to Investigators.
3. Test the claim the recommendation rests on.
4. Check before you report. Reopen, from the notes, the source behind each finding the verdict depends on. When the result will be published, or a wrong claim is costly, spawn a Reviewer from another model family (`subagents` skill) on the notes, with no hint of your verdict.
5. Report, and change nothing until the user picks.
6. Write a tracked doc only when the user asks.
7. When the user picks a direction, switch to the `build` playbook. To park it, run the `file-issue` skill. Stop gathering once the user has decided.

**Reply:** the `research` skill's report.
