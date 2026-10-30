# Research

You own the evidence and the recommendation. The user owns the question, the constraints and the decision.

1. Pin the question before you gather anything. Write down the decision it serves and the constraints that rule options out (platforms, how it ships, accounts and keys, budget, what is already installed). When the request carries a guess ("I assume it's X"), list it as one candidate and test it like the others. Find what you can in the repo and on the machine. Ask only about what you can't find, each question with your default. Before any search, write the question and constraints at the top of `.evidence/<task>/research/notes.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints. Every research task gets this file, however small it looks.
2. Start with the closest sources: the user's own repos (README, `docs/`, notes and decision records), PRs and past sessions, the installed tool (its `--help`, its source) and the machine. Then primary sources outside: official docs, the project's repo, the paper, the terms page. Search results and comparison posts are leads, never evidence.
3. Record the findings in the notes after each round of searches or fetches, not at the end. The notes hold:
   - each claim with its source, how far that source was read (in full, abstract, summary, couldn't open), and whether the source states it or you inferred it. A fetch tool that answers a prompt about a page returns a summary, read in full only for the text it quotes
   - the queries run and places searched, including the ones that found nothing
   - contradictions, with both sources
   - sources you couldn't search, and why (no key, paywall, no access)

   When the question splits into independent strands, or needs many sources, run the `orchestrate` skill with one read-only Investigator per strand. Each records into its own `<strand>.md` next to the notes the same way, and returns a short summary; the verdict is yours. Its brief gives today's date, numbered questions, the constraints from step 1 and the sources to try first. Read an investigator's file when a finding needs checking, not by default.
4. Test the claim the recommendation rests on: run it in a scratch directory outside the repo, measure it on the user's data, or open its primary source. Installing anything, or changing anything outside the scratch directory, waits for the user. "It's easy" from the docs alone is a guess. Mark every claim you did not test `not verified`.
5. Check before you report. Reopen, from the evidence file, the source behind each finding the verdict depends on. When the result will be published, or a wrong claim is costly, spawn a Reviewer from another model family (`model-roles` skill) on the evidence files, with no hint of your verdict.
6. Report, and change nothing. A verdict per question, in the order asked, then the evidence, with a table where options compare. Then contradictions, what you didn't verify or couldn't find, and what you'd do next. Each decision you leave to the user carries how it works today, the trade-off and your default. Answer the question asked; ideas beyond it get one line. Define any term the user may not know.
7. Move the findings into a tracked doc only when the user asks. Write it from the evidence files, under `docs/research/` or the repo's equivalent, with source dates, how far each source was read, and what wasn't found. Ask whether it will be public before it quotes the user's sessions, projects or numbers.
8. When the user picks a direction, switch to the `build` playbook. To park it, run the `file-issue` skill. Stop gathering once the user has decided.

**Reply:** the verdict per question, the evidence behind each with how far it was checked, contradictions and what is not verified, and the next step for the user to approve.
