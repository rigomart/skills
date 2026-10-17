---
name: glossary
description: Keep a project's ubiquitous language in GLOSSARY.md, one name per concept, shared by the people and agents who work on it. Seeds a glossary from the code, UI copy, docs and issues when none exists, challenges fuzzy or conflicting terms during work and records each settled term as it happens, and wires one line into AGENTS.md so every agent reads it. Use when naming a new concept, when one concept has two names or one word means two things, when discussing a project's terminology or ubiquitous language, or when creating or editing GLOSSARY.md.
---

# Glossary

A glossary holds the project's ubiquitous language: one name per concept, used the same way in conversation, issues, code, UI copy and docs. With it, a person and an agent mean the same thing by the same word, and a cold agent learns the domain without reverse-engineering it from code.

Reading the glossary is every agent's job, through one line in `AGENTS.md` (step 4). This skill is for changing it: seeding it, sharpening it, keeping it true.

## 1. Find it

- `GLOSSARY.md` at the repo root holds one context. When the same word means different things in different parts of the system (an "account" in billing and in auth), a `GLOSSARY-MAP.md` at the root lists one `GLOSSARY.md` per context and how the contexts relate. Most repos need one file.
- A glossary may already exist under another name: `CONTEXT.md`, `docs/glossary.md`, a domain section in `AGENTS.md` or the README. Adopt it where it is instead of starting a second one, and offer to move it to `GLOSSARY.md` only if the user wants that convention.
- Open [references/format.md](references/format.md) before you write or edit an entry.

## 2. What belongs

- **Domain terms only.** A word earns an entry when an outsider would get it wrong: a concept users, the owner or the code name in a way specific to this project. General programming concepts (cache, retry, webhook) stay out, however often the code uses them.
- **What it is, not how it works.** One or two sentences. No file paths, tables or implementation decisions. The one exception is a `_Code_` line when the code names the concept differently from the term, because an agent searching the code will not find it otherwise.
- **One name per concept.** When a concept has several names, pick one and list the others under `_Avoid_`. An avoid list keeps one name for that concept; it does not ban the word in its everyday senses.
- **The present tense.** The glossary describes what ships. A term for something planned lives in its spec or ADR until the code lands, and the change that ships it updates the glossary.
- Nothing else: the glossary is not a spec, a scratch pad or a decision log.

## 3a. Seed a glossary

When none exists, draft one; do not wait for terms to come up one at a time.

1. **Harvest** candidate terms from where the domain shows: the words users see (UI copy, CLI help, error messages, emails), the code's names (types, tables, modules, routes), the README and docs, issue and PR titles, and the user's own words in this conversation.
2. **Find the collisions.** These are the entries worth writing: one concept with several names (the UI says "Project", the code says `Workspace`, the docs say "space"), one word with several meanings ("account" for a login and for a paying organization), and code-only words that leak into issues or UI copy.
3. **Draft** the entries a newcomer would get wrong, usually 5 to 20 to start, in the format. For each collision, take a default and say why in a clause ("the UI is what users read, so Project wins; `Workspace` stays the code name until a rename").
4. **Ask** about the collisions in one round, each with your default first. Which name is canonical is the user's call; how the code and docs use each word is yours to find out.
5. **Write** `GLOSSARY.md`, then wire it in (step 4).

Done when every collision you found is either settled (one term, the others under `_Avoid_`) or listed under Flagged ambiguities with what is still open.

## 3b. Sharpen during work

Whenever terms are in play (designing, planning, naming, reviewing), hold the conversation to the glossary:

- **Challenge a conflict at once.** When anyone, you included, uses a term against its entry, quote the entry: "The glossary defines Cancellation as voiding a whole Order; you mean refunding one line. Is that a Cancellation or a Refund?"
- **Sharpen fuzzy words.** An overloaded or vague word gets a precise proposal: "By account, do you mean the Customer or the User?"
- **Force the boundary with a case.** When the relation between two concepts is unclear, invent a concrete edge case that makes someone decide: "Can one Order belong to two Customers? What is a Draft once it is sent?"
- **Check the code.** When someone states how a concept behaves, check that the code agrees, and surface any contradiction.
- **Name new concepts plainly.** Reuse an existing term before coining one. Otherwise pick the plainest familiar word that does not mislead, and check it against every entry and every `_Avoid_` list.
- **Record as you go.** When a term settles, edit `GLOSSARY.md` right then rather than batching edits for the end. A term that will not settle goes under Flagged ambiguities.

## 4. Wire it in

Add one line to `AGENTS.md`, or to `CLAUDE.md` if that is the only agent file. Point at the file instead of copying terms into it:

```md
Use the terms in `GLOSSARY.md` for the concepts it defines, in conversation, code, issues, commits and UI copy. When a concept you need is missing, or a term seems to mean two things, say so instead of inventing a synonym.
```

Adapt the path for a `GLOSSARY-MAP.md`. If the line is already there, leave it.

## 5. Make the language stick

Prose rules slip; structure holds.

- **Rename the code.** When a `_Code_` line records a mismatch, the lasting fix is renaming the code to the term. Propose the rename as its own change; drop the `_Code_` line when it lands.
- **Check what keeps slipping.** When an avoided term comes back a second time (in review, in code, in UI copy), propose a check where it matters: a vocabulary rule in a prose linter the project already runs, or a lint rule on identifiers, scoped to the wrong sense. Adding a tool is the user's call. Propose it with the reason, and follow any dependency-vetting rule the user or the project has (such as running `depfit`).

## 6. Hand over

Report the terms added or changed, each collision and how it was settled, the ambiguities left open, whether the `AGENTS.md` line is in place, and any rename or check you proposed.
