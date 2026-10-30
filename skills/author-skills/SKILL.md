---
name: author-skills
description: Write, revise or review a skill or playbook, and prove it on a fresh agent. Use when creating, editing, reviewing or auditing a skill or playbook, or when one fails, gets skipped or doesn't fire.
---

# Author skills

You write and judge text for an agent that reads it cold, mid-task, and does what it says. A skill's text says what it intends; past sessions show what it does. You own the text's voice and the evidence behind each change. The user picks which changes to make.

## Pick the case

| The request | Open |
| --- | --- |
| Write a new skill or playbook, or revise one | [references/write.md](references/write.md) |
| Review or audit a skill or playbook, or find why it fails, gets skipped or doesn't fire | [references/review.md](references/review.md). The changes the user picks then go through `write.md`. |

The design rules and the standard below apply in every case.

## Design rules

Apply each rule that fits. In your reply, name each rule you applied and the decision it changed; a name with no decision behind it was not applied.

### One owner

Every rule, step and fact lives in one place. Everywhere else names that place. Copies drift apart, and two owners of one rule end up disagreeing; the agent then follows whichever it read last.

- Before writing a rule, search for it and for its opposite in every skill and playbook that loads alongside it.
- Found a copy: keep the one where its work lives, and replace the other with a reference.
- Two files disagree: decide which one owns the work and delete the rule from the other. A third sentence reconciling them makes three owners.
- A rule repeated in a subagent's brief is fine: a brief is a message, not an owner.

Wrong: a commit skill says "run the full test suite first", a testing skill says "run only the tests the change touches", and you add "unless the commit skill is running" to the testing skill.
Right: decide which skill owns when tests run, delete the rule from the other, and have it name the owner.

### Subtract before you add

Before adding a sentence, step or check, look for what to delete or move instead. Every added rule competes with the others, and agents follow fewer of them as the count grows.

- A second fix in the same area means the shape is wrong. Stop patching and find the premise the fixes share: a rule in the wrong layer, two owners, a missing structure.
- Order: delete what's wrong or unused, move what's in the wrong place, and only then add.

Wrong: a third special-case sentence in a skill, after two earlier ones for neighboring cases.
Right: find what the three cases share, and write that once in place of all three.

### Encode in structure

A rule that must hold every time goes in something that fails when it is broken: a script, a check, a schema, a file the next step reads. Prose is for judgment. Nothing fails when an agent skips a sentence.

- Rank the fixes: make the mistake impossible (a data shape, an API), block it (a check whose error names the fix), catch it (a test), and only then write it down.
- A rule broken twice despite clear wording is a candidate for a check.
- State a later step needs goes in a file with a named moment to update it ("before you reply"), not in a reply.

Wrong: "Make sure every link resolves."
Right: a script that fails on a broken link and prints which one.

### A repeat before a rule

Change a shared skill or playbook for what happened at least twice, or what the user asked for. A fix written from one session fits that session and shifts behavior in others.

- Count sessions, not findings. The same problem in two sessions is a pattern; one is an anecdote.
- Repeats from one project about that project's content are that project's pattern: the fix goes in the project (its `AGENTS.md`, its own skills), not a shared skill.
- A workaround for one harness (its time limits, its tool names) stays out of skills that run in several.
- One costly failure may earn a check, rarely a sentence.

Wrong: one session's agent forgot to seed a database, so a shared skill gains a sentence about seeding.
Right: note it, and change the skill when a second session shows it; if it's one project's database, the note goes in that project.

### Process in playbooks, judgment in skills

A playbook owns the order of the work: the steps, loops with counts, stop points, handoffs and the reply. A skill owns how to do one kind of work well, by topic. A skill that carries its own order makes every caller reach inside it and override parts, and two processes then run at once with no clear owner of "done".

- A skill that playbooks or other skills load is organized by topic (what counts as proof, what's in scope, the report), with no numbered steps, no "you own this until", no "stop after".
- A skill only a person runs on its own (a generator, a review) may be a sequence of steps.
- A caller that needs part of a skill, or has to override part of it, means that part is in the wrong place. Move process to the playbook, and a reusable piece of judgment to its own skill.
- A skill never names its callers.

Wrong: a playbook step says "deploy as the `release` skill's step 3 says, but skip its approval".
Right: the playbook owns the order and the approval; the `release` skill says only how to build and verify a release, and the step loads it whole.

### Reference the whole

Point at a whole skill, playbook, script or file, never at a step number or a heading inside another one. Renaming a heading or renumbering a step breaks the reference without any error, and whoever edits the target can't see who depends on it. A missing file or skill fails loudly.

- References point down: playbooks to skills, skills to skills. Nothing points at a caller.
- A skill's report is part of the whole. A caller may ask for it by what it is ("reply with the `release` skill's report"), and the skill keeps one report for that phrase to mean.
- Moving to another playbook names it, and never runs some of its steps.
- Inside one skill, its own files and sections may point at each other: one edit sees them all.

Wrong: "run steps 4 and 5 of the `deploy` playbook", "follow the `release` skill's **Rollback** section".
Right: "switch to the `deploy` playbook", "load the `release` skill".

## The standard

### Invocation and description

- **Model-invoked** (omit `disable-model-invocation`): the agent reaches for it on its own, or another skill must reach it. Its description sits in context on every turn, so it pays for itself only if the agent would usefully fire it unprompted.
- **User-invoked** (`disable-model-invocation: true`): fires only when a human types its name, and no other skill can call it. Use it for generators, setup and heavy runs a person should start. Its description is a one-line summary for a person browsing commands.

The description is the trigger: the agent reads it to decide whether to open the skill, so a "when to use" section in the body never fires. For a model-invoked skill, say what it does in a sentence, then `Use when` and one trigger per distinct case, led by the word people actually type. Synonyms for one case are one trigger. Keep it to two short sentences, under 250 characters; how the skill works belongs in the body. `name` is kebab-case and matches the folder.

A playbook has no description: its row in the `do` skill's table is its trigger. Write the row in the phrases people type, and when a request would fit a nearby row too, change a phrase until it fits one.

### Body

- **Topics, or steps,** as **Process in playbooks, judgment in skills** says. In a skill of steps, rules and facts the agent consults on demand go under their own headings, not inside a step.
- **A check where done is fuzzy.** End such a step or topic on a condition the agent can test: "every changed model accounted for", not "understand the code".
- **Inline what every case needs.** Move what only some cases reach into `references/<topic>.md`, one level deep, and make the linking line say when to open it. Keep a concept's definition, rules and caveats under one heading. When `SKILL.md` runs past about 200 lines, split it by case.
- **Scripts for deterministic work.** Validation, scaffolding and parsing go in `scripts/`. The skill says how to run each one and what its output means.
- **Delegate by name** ("ship with the `ship-changes` skill if it is installed"). A user-invoked skill cannot be reached from another skill, so tell the user to run it.
- **Point at the environment.** `package.json`, `--help`, config and the directory layout stay true on their own; a copy of them goes stale. Write down only what looking cannot find: the unwritten convention, the reason behind a choice, the gotcha.

### Prose

- Keep only prose that changes a decision. Test each sentence against what the model does by default ("be careful", "be thorough", "make sure to" change nothing), and delete a failing sentence whole rather than trimming it.
- Tell it to do the thing. Give the reason only when a rule looks arbitrary without one, or when the agent must judge edge cases from it.
- State the behavior you want. A prohibition puts the unwanted behavior in front of the agent; use one only as a hard guardrail, paired with what to do instead.
- Reach for a word the model already knows (draft, tracer bullet, red) in place of a sentence that circles the idea, then use that word every time. Use the project's glossary terms for its concepts.
- For a rule that needs judgment, show the failure it prevents: a short wrong-and-right pair beats an adjective.
- Write for the cold reader: nothing like "as discussed" or "the issue above".
- Skills get shared and published. Keep personal and private details out of the text and examples.
- Follow the prose rules the user or the project sets (a writing skill, a style section in `AGENTS.md`).

### Validate

Run [scripts/check-skill.sh](scripts/check-skill.sh) on every skill folder you touched or review (`bash <path>/check-skill.sh skills/foo skills/bar`) and fix every `FAIL` line it prints. It checks frontmatter, `name`, `description` and its length, and relative links. Check by hand what it does not: every skill the text names exists, and every command and script runs from where the skill says to run it.
