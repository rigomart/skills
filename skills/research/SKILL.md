---
name: research
description: Answer a question that needs evidence gathered first, from local and outside sources, and recommend. Use when asked to research, look into, compare options, judge feasibility ("how could we build X"), or validate sources or claims.
---

# Research

The research serves a decision the user owns. This covers where to look, what to record, what counts as checked, and the report.

## Pin the question

Write down the decision the research serves and the constraints that rule options out: platforms, how it ships, accounts and keys, budget, what is already installed. Find what you can in the repo and on the machine, and ask only about what you can't find, each question with your default. A guess in the request ("I assume it's X") is one candidate, tested like the others.

## Notes

Every research task keeps `.evidence/<task>/research/notes.md`, excluded from git through the file `git rev-parse --git-path info/exclude` prints, however small the question looks. Start it from this skeleton before any search, and fill each section after each round of searches or fetches:

```markdown
# <the question>
Decision: <what it serves>. Constraints: <what rules options out>.

## Claims
- <claim>. Source: <url or path>, read <in full | abstract | summary | couldn't open>, <stated | inferred>.

## Searched
- <query or place>: <what it found, or nothing>

## Contradictions
- <claim A, source> vs <claim B, source>

## Couldn't search
- <source>: <why: no key, paywall, 404, no access>
```

A fetch tool that answers a prompt about a page returns a summary, read in full only for the text it quotes. An empty section says `none`.

## Sources

Closest first: the user's own repos (README, `docs/`, notes and decision records), PRs and past sessions, the installed tool (its `--help`, its source) and the machine. Then primary sources outside: official docs, the project's repo, the paper, the terms page. Search results and comparison posts are leads, never evidence.

## Investigators

When the question splits into independent strands, or needs many sources, fan out to one read-only Investigator per strand, with the `subagents` skill. Each records into its own `<strand>.md` next to the notes, as **Notes** says, and returns a short summary; the verdict is yours. Its brief gives today's date, numbered questions, the constraints and the sources to try first. Read an investigator's file when a finding needs checking, not by default.

## Test the deciding claim

Test the claim the recommendation rests on: run it in a scratch directory outside the repo, measure it on the user's data, or open its primary source. Installing anything, or changing anything outside the scratch directory, waits for the user. "It's easy" from the docs alone is a guess. Every claim you did not test is `not verified`.

## Report

Short and plain, and change nothing:

- **Verdict:** one per question, in the order asked.
- **Evidence:** behind each verdict, with how far it was checked; a table where options compare.
- **Open:** contradictions, what is `not verified`, and what you couldn't find.
- **Decisions:** each one left to the user carries how it works today, the trade-off and your default.
- **Next:** the step for the user to approve.

Answer the question asked; ideas beyond it get one line. Define any term the user may not know.

## A saved doc

Only when the user asks. Write it from the notes, under `docs/research/` or the repo's equivalent, with source dates, how far each source was read, and what wasn't found. Ask whether it will be public before it quotes the user's sessions, projects or numbers.
