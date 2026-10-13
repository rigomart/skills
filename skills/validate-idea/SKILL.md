---
name: validate-idea
description: Shape a raw product idea into a direction before anything is built. Grounds itself in the project's docs, answers with a draft built on stated defaults instead of a round of questions, settles how a shape looks or behaves with a prototype, converges with the owner, then lands the chosen prototype with a proposed ADR and files a spec issue and one issue per slice. Use when the user shares a thought, a pain point, a "what if", or a feature idea for their product, even a vague one ("thought right now…", "how should we deal with X", "what about adding Y"), or several at once.
---

# Validate an idea

The owner brings ideas from their own use of the product, from a guess about other users, or from nowhere in particular. Find out whether there is a real problem, whether the product should hold it, and what the smallest fitting shape is.

**Draft first, ask second.** The owner trusts your defaults and reacts faster to a proposal than to a questionnaire. Every reply carries a recommendation. Decide everything you can, show what you decided, and let the owner reverse it. Never ask a question without your default.

No product code in this skill. Its outputs are a verdict and, when the idea goes ahead, a prototype, a proposed ADR and filed issues.

**Keep the owner's life out of anything written down.** Repositories and issues are often public (`gh repo view --json visibility`), and private ones get shared. Ideas often start from something personal (a relative's health, money, relationships, an employer). Use it in the conversation, but in issues, ADRs, docs, prototypes, sample data and commit messages write only generic cases ("a relative's chronic condition", "an evening check-in"): no family members, conditions, names, places or anything that points at the owner. Before filing or committing, reread the text for personal details. If a personal case seems necessary, ask first.

## 1. Ground yourself

Read before forming an opinion, and never ask what these answer. Projects name them differently; look for:

- **The glossary**: `CONTEXT.md`, `GLOSSARY.md`, a domain section in `AGENTS.md` or the README. Use its terms for its concepts. A list of words to avoid keeps one name per concept; it does not ban everyday words.
- **The product direction**: a vision, thesis, principles, roadmap or "not now" list (`docs/product-direction.md`, `docs/vision.md`, `PRODUCT.md`). An idea may already be parked there, with the evidence that would unpark it.
- **The decisions**: ADRs the idea touches (`docs/adr/`, `docs/decisions/`).
- **Prior attempts**: GitHub issues, open and closed, on the same problem.
- **The product as it ships**: the code and the running app, for the step-by-step walk below.

When the project has no written thesis or principles, infer them from the product and the README, state them in the draft, and make confirming them one of your questions.

## 2. Draft

Answer the idea with one reply, in this order:

- **Problem.** The situation, in the owner's words. What fails, and for whom: the owner, a plausible other user, or a thought experiment (say which; it changes how much evidence there is). The owner's proposal, if they brought one, kept apart from the problem: the problem is what gets validated. Keep the owner's phrasing; a phrase like "the same move every day" often names the right model before any analysis does.
- **Thesis.** Which part of the product's thesis or principles the problem serves, and where it pulls against them: work the product deliberately leaves to other tools, upkeep the user has to do for it to stay true, a job the product says it does not do. If it serves none, say so. Never reject an idea because another tool has it.
- **Today.** Walk the situation through the product as it is, step by step, using its real screens, commands and concepts, and list where it rubs, concretely ("five date picks a week", "three commands to undo one mistake").
- **Cases.** 6 to 10 situations that vary along the dimensions the product spans (for a personal tool, parts of life; for a team tool, team sizes and roles; for a developer tool, project shapes and scales), plus durations and intensities, as a table: situation, what the idea would hold, how long. Include one that stresses the idea and one where it should not apply. Then what the cases show, as short bullets: plurality, grain, failure modes, unknowns. These findings drive the shape.
- **Verdict.** Solved today, park it, or go (step 5).
- **Shape.** For a go, the smallest shape that fits, with a small text mockup of the screen or output it changes, and one case walked through it: setup, normal use, the edge (a miss, an error, an interruption), the end. Check it against the principles one by one. Name every ADR or glossary rule it contradicts (allowed, on purpose, recorded in the ADR) and what it costs: new concepts, migrations, surfaces. Prefer reusing a concept the user knows over adding one, and one concept with optional parts over two. Name the shapes you passed over, smaller and larger, a line each with why. Name any new concept with the plainest familiar word that does not mislead, following the glossary's naming rules if it has any.
- **Defaults I took.** A table of every decision that has a sensible default: the decision, your choice, why in a clause, and the word that reverses it.
- **Prototype.** How to open it, when the shape has a question about how it looks or behaves (step 3).
- **Questions** (below).

### Questions

Ask only what passes both tests: nothing you could read or run answers it, and only the owner can decide it (product direction, taste, what they would do in their life or work). Everything else is a default in the table.

There is no fixed count. Ask every question that passes, in one round, as multiple choice with your recommendation first (the question tool takes four at a time; call it again for more). Order them so the ones that would change the shape come first. An unanswered question keeps your default. When more than about six pass, the idea is several ideas: split it, say how, and draft the first.

## 3. Prototype instead of asking

When a fork is about layout, interaction, density or feel, build it and let the owner choose by using it. Build it in the same turn as the draft, on a branch for the idea.

- **Where.** The place the project keeps prototypes: a design lab, Storybook, a playground app, a dev-only route. If it has none, add a throwaway dev-only page or route. For a CLI or API, a stub command or a script that prints the proposed output. Use the product's own components and data hooks so it looks like the product. Speed over polish, no tests.
- **Variants.** `current`, as it ships today, then two or more directions that differ in whole shape, not in a detail of one shape. Include one you would not have proposed. Make each variant reachable on its own (a query parameter, a story, a flag) so the owner can switch between them.
- **Data under strain.** When the directions need data to be judged (long text, many items, late and repeating dates, empty states), seed it through the product's real commands or fixtures, not hand-written markup.
- **Check it, then send it.** Start the dev server and open each variant yourself, with a browser tool if you have one, under the data you seeded, to check it renders and holds up. Then give the owner one link or command per variant.
- **Commit every variant** on the idea's branch. That commit keeps the directions that lose.

A question about a rule with nothing to look at (does it give sensible results across the cases?) gets a small script or test run against the cases table instead.

When you work where the owner cannot reach your `localhost` (a cloud session), push the branch and say what to open after checking it out.

## 4. Converge

The owner reacts to the draft and to the prototype. Expect several rounds. Pushback like "too complex", "doesn't feel right" or "what if it were like X" is the most useful signal: find what it is reacting to, then reshape, redraft and rebuild variants rather than defend. Say so when a suggestion is close to something already rejected, and what actually differs. Keep the defaults table current: a reversal changes its row.

When asked for a summary, give the shape in one line, the mockup or the chosen variant, the rules, what changes in the repo, and the remaining questions.

## 5. Close with a verdict

- **Not a problem / solved today:** explain how to do it with the product as it is. Nothing to file.
- **Park it:** record it where the project keeps parked directions (an Open Directions or Not Now section in the product doc, or an issue with the project's label for later), naming the evidence that would justify building it. Delete any prototype.
- **Go ahead**, once the owner agrees with the direction:
  1. **Keep the chosen prototype.** Prune it to `current` and the chosen variant. It is how the implementing agent knows what the feature looks like; a spec cannot carry that. The pull request that ships the feature deletes it.
  2. **Write an ADR** with the next number, status Proposed, in the project's ADR folder (`docs/adr/` if it has none): what it amends or supersedes, the decision, the considered options (each variant and why it lost, with the commit from step 3 that keeps them), what is left open, and the exact glossary changes to apply when it ships.
  3. **Keep the docs honest without writing the future into them.** The glossary and product direction describe the present, so leave the glossary alone until the code ships: the implementing agent applies the ADR's glossary changes. Product direction gets at most a one-line item linking the spec issue.
  4. **Ship the prototype and the ADR in one pull request** with the `ship-changes` skill if it is installed (`docs(adr): propose <decision>`). The prototype has to be on the default branch for any agent picking up the issues to find it.
  5. **File the spec issue, then one issue per slice.** Search for duplicates first.

### The spec issue

Title `Spec: <shape>`. Sections:

- **Problem**, with the cases table and what they show.
- **Shape**, in a few sentences and the mockup.
- **Prototype**: where it lives, the variant to open, the data to load, and the commit that keeps every variant.
- **Decisions**: the defaults table as settled, including what the owner reversed.
- **Slices**: the slice issues, in delivery order.
- **Out of scope**, and **Rejected shapes** with why.

Leave implementation choices to the implementing agent unless one was settled here (a storage choice, an ADR it amends).

### Slice issues

One issue per pull request, in delivery order, each landable and checkable on its own. Each says what changes for the user, what it depends on, which prototype variant it must match if any, what is out of scope, and **You see**: the results in the real product, concrete enough to check (the action, then the screen state or output that follows). Link the spec, and add the label the project uses for work ready to pick up, if it has one.

## Several ideas at once

Ground once. Draft each idea briefly (problem, thesis test, verdict, shape in a line) and return one table. Go through the full steps only for the ones the owner picks.
