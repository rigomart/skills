---
name: unslop
description: Edit prose so it reads easily and drops the tells of AI writing, keeping every fact. Use when asked to unslop, humanize, tighten or make text easier to read, or to check writing for AI tells.
---

# Unslop

Slop is text that makes the reader work for nothing: a sentence that says nothing, a fancy word where a plain one exists, one shape repeated until it reads machine-made. You edit for the reader. The tells below matter because they cost the reader time and trust. Passing an AI detector is a side effect, not the goal, so when a rule and readability disagree, readability wins.

## What stays fixed

- **Meaning.** Every claim, number, name, path, command, flag, code span and link survives at the same strength. "May" stays "may", a condition stays attached, and nothing new appears: no requirement, example, caveat or aside the source didn't have. When you can't tell whether an edit shifts meaning, keep the original wording.
- **Voice and register.** A casual note stays casual, reference stays dry, and a section you edit matches the rest of its file.
- **What isn't prose.** Code blocks, quotes from other people, UI labels and the project's defined terms (its `GLOSSARY.md`, if it has one).
- **Scope.** The text the user named, or the text you wrote this turn. Text around it stays untouched.

## Make it easy to read

- **Lead with the point.** The first sentence of a doc, section or message gives the reader what they came for: the answer, the change, the ask. Background follows, if it's needed at all.
- **One idea per sentence.** Split a sentence the reader has to read twice. A long sentence that carries one idea with its condition is fine; vary length so the text doesn't tick like a metronome.
- **Plain words.** "Use", not "utilize" or "leverage". "Help", not "facilitate". "Is" or "has", not "serves as" or "boasts".
- **Concrete over abstract.** Name the mechanism, the number, the file. "A column rename fails the build", not "schema changes can cause issues". A sentence that could appear unchanged in another project's docs says nothing about this one: cut it.
- **Name who acts.** "The loader parses the file", not "the file is parsed". Passive is fine when the actor is unknown or beside the point.
- **One name per thing.** Pick a term and repeat it. Swapping in synonyms for variety makes the reader wonder whether there are two things.
- **Whole sentences.** Keep articles and verbs, and spell out arrows and abbreviations. "Bad date → exit 2" becomes "A bad date exits with code 2."
- **Cut what does no work.** Filler ("in order to", "it's worth noting that"), intensifiers ("very", "truly", "significantly"), stacked hedges, and a closing line that restates the paragraph.
- **Format for scanning.** Sentence-case headings, lists for real sets and sequences, prose for reasoning, bold only for the one thing a skimmer must not miss.

## Tells to remove

The scan below catches the word-level ones. The shapes need your eye.

**Words.** "Delve", "tapestry", "testament", "pivotal", "crucial", "intricate", "underscore", "showcase", "foster", "seamless", "robust", "landscape", "realm", "elevate", "unlock", "additionally", "moreover". Abstract metaphor nouns: "north star", "flywheel", "substrate", "surface" (for an API), "wedge". Use the word you'd say out loud.

**Shapes.**

- "Not just X, but Y" and "It's not X, it's Y". State Y.
- A trailing -ing clause that editorializes: "..., highlighting the need for better tooling." Delete it, or make it a claim with a source.
- Forced threes, and sibling items forced into one identical shape. Use the real count, and let items that differ read differently.
- A wall of "must", "always", "never", "exactly". Keep the ones the meaning depends on and state the rest in plain present tense.
- Unbacked claims: vague attribution ("experts say", "many teams find") and praise ("fast", "secure", "reliable") the text never supports. Back the claim with the fact behind it (a benchmark, the encryption used) or cut it. Dropping "experts say" and keeping the claim leaves it just as unbacked.
- False ranges ("from startups to enterprises") where the two ends aren't on one scale. List what you mean.
- Completeness hedges ("and more", "and similar cases", "etc."). Name the cases or stop.
- Signposts ("Here's the thing:", "Let's dive in", "The key insight is", "In short"). Say the point.
- Mannered prose: aphorisms, rhetorical fragments, code that "holds" or "rides along", a colon used as a drumroll mid-sentence.

**Punctuation and format.** No em dashes, and no hyphens or en dashes standing in for them: end the sentence or use a comma, and parentheses for a true aside. Straight quotes, not curly. No decorative emoji. No title-case headings. No bullets that open with a bold label restating the line ("**Performance:** Performance improved").

**Chat artifacts.** Openers ("Great question!", "Certainly!"), closers ("I hope this helps", "Let me know if..."), agreement for its own sake ("You're absolutely right"), and narration of what you're about to do.

## Don't overcorrect

- **Faked casualness reads fake.** Slang, jokes, exclamation marks and planted typos read as someone imitating a person. Aim for plain and competent.
- **A rarer synonym is the same tell.** "Delve" becomes "look at", not "dig into".
- **A rule that makes a sentence worse loses.** Fix the sentence another way, or leave it alone.
- **Precision stays.** An "exactly one" the reader relies on is not slop.

## Scan

Run the bundled scan on the result, from this skill's folder or with its full path:

```bash
bash scripts/scan.sh <file>...
pbpaste | bash scripts/scan.sh -
```

It skips fenced code and inline code, prints `<file>:<line>: <rule>: <match>` per hit, and exits 1 if anything was flagged. Each word hit is a candidate: keep it when it is the plain word for the thing (a "robust" estimator in statistics, a "landscape" photo). Em dashes, curly quotes and chat phrases have no such exception. Text you're working on in the reply itself goes through the scan via a temp file or stdin.

The scan sees words, not shapes or rhythm. After it passes, reread the text once from the top as its reader would. For long text that goes out (docs, a README, a post), also give a fresh subagent only the rewritten text, and ask it to quote each sentence it had to read twice or that reads machine-written. Pick its model with the `subagents` skill if it is installed. Fix what it quotes.

## Report

The report is prose too, held to this skill: plain bullets, no bold labels.

- What changed, as kinds and counts rather than a diff recital: "cut 9 filler phrases, split 4 sentences, replaced 6 em dashes".
- Each edit that might have shifted meaning, quoted before and after.
- The scan result, and whether a cold reader ran.

When the user asked only for a check, change nothing: list each finding with its line and a suggested rewrite.
