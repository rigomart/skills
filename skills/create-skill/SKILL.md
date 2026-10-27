---
name: create-skill
description: Write or revise a skill and prove it on a fresh agent. Use when creating or substantially editing a skill, fixing a description that doesn't fire, or turning a repeated correction into a skill.
---

# Create a skill

You write for an agent that reads the skill cold, mid-task, and does what it says. You own the skill's voice: draft it, cut it, and prove it before you hand it over.

## 1. Check that a skill is the fix

- **A repeat earns a skill.** The same correction or the same workflow, twice, or the user asking for it. One odd session is an anecdote.
- **Structure beats prose.** Rank the fixes: make the mistake impossible (a data structure, an API shape), block it (a type, or a lint or CI check whose error names the fix), catch it with a test, and only then write it down. Nothing fails when an agent skips a skill. When the fix is structural, ship only the structural fix. A skill is right for workflows and judgment that no check can carry.
- **Extend before adding.** Search the installed skills, the project's and the user's, for one that covers this case, and extend it. A new skill earns its place with a trigger of its own, or when another skill must reach it.

Done when you can name the workflow or failure, the evidence for it, and why no check or existing skill covers it. If one does, say so and propose that instead.

## 2. Gather from evidence

Build the content from what happened and what exists, not from general knowledge:

- The conversation or transcript where the workflow ran, and every correction the user made in it.
- The repo: scripts, config, conventions, `AGENTS.md` or `CLAUDE.md`, the project's glossary.
- Prior art: skills that do something close.
- For a rewrite, the skill itself, its references and its git history. Keep what the history shows was learned.

Ask the user only what you cannot read or run, each question with your default. Every command, path and name the skill gives comes from the repo and has been run. No placeholders.

## 3. Choose invocation, then write the description

- **Model-invoked** (omit `disable-model-invocation`): the agent reaches for it on its own, or another skill must reach it. Its description sits in context on every turn, so it pays for itself only if the agent would usefully fire it unprompted.
- **User-invoked** (`disable-model-invocation: true`): fires only when a human types its name, and no other skill can call it. Use it for generators, setup and heavy runs a person should start. Its description is a one-line summary for a person browsing commands.

The description is the trigger: the agent reads it to decide whether to open the skill, so a "when to use" section in the body never fires. For a model-invoked skill, say what it does in a sentence, then `Use when` and one trigger per distinct case, led by the word people actually type. Synonyms for one case are one trigger. Keep it to two short sentences, under 250 characters; how the skill works belongs in the body. `name` is kebab-case and matches the folder.

## 4. Lay out the body

- **Steps in order, reference apart.** Rules and facts the agent consults on demand go under their own headings, not inside a step.
- **A check where done is fuzzy.** End such a step on a condition the agent can test: "every changed model accounted for", not "understand the code".
- **Inline what every case needs.** Move what only some cases reach into `references/<topic>.md`, one level deep, and make the linking line say when to open it (`create-verification-skill` routes by surface this way). Keep a concept's definition, rules and caveats under one heading. When `SKILL.md` runs past about 200 lines, split it by case.
- **Scripts for deterministic work.** Validation, scaffolding and parsing go in `scripts/`. The skill says how to run each one and what its output means.
- **Delegate by name.** When another skill covers a step, name it ("ship with the `ship-changes` skill if it is installed") and do not restate it. A user-invoked skill cannot be reached from another skill, so tell the user to run it.
- **Point at the environment.** `package.json`, `--help`, config and the directory layout stay true on their own; a copy of them goes stale. Write down only what looking cannot find: the unwritten convention, the reason behind a choice, the gotcha.

## 5. Write the prose

- Keep only prose that changes a decision. Test each sentence against what the model does by default ("be careful", "be thorough", "make sure to" change nothing), and delete a failing sentence whole rather than trimming it.
- Tell it to do the thing. Give the reason only when a rule looks arbitrary without one, or when the agent must judge edge cases from it.
- State the behavior you want. A prohibition puts the unwanted behavior in front of the agent; use one only as a hard guardrail, paired with what to do instead.
- Say each thing in one place. A rule repeated in two places drifts, and weighs more than it should.
- Reach for a word the model already knows (draft, tracer bullet, red) in place of a sentence that circles the idea, then use that word every time. Use the project's glossary terms for its concepts.
- For a rule that needs judgment, show the failure it prevents: a short wrong-and-right pair beats an adjective.
- Write for the cold reader: nothing like "as discussed" or "the issue above".
- Skills get shared and published. Keep personal and private details out of the text and examples.
- Follow the prose rules the user or the project sets (a writing skill, a style section in `AGENTS.md`).

## 6. Validate

Run [scripts/check-skill.sh](scripts/check-skill.sh) on every skill folder you touched (`bash <path>/check-skill.sh skills/foo skills/bar`) and fix every `FAIL` line it prints. It checks frontmatter, `name`, `description` and its length, and relative links. Check by hand what it does not: every skill the text names exists, and every command and script runs from where the skill says to run it.

## 7. Prove it cold

A skill that was never followed is a draft. Prove it with a fresh agent:

1. **Write the expected results** for each part of the task before the run: the action per planted case, the role per item, the output a step should produce. Keep them out of the agent's prompt and paths.
2. **Run a blind agent.** Give a fresh agent only the repo and an organic task, written the way a user would type it ("prove that X shows Y after Z", not "test this skill"), on the model the skill normally runs on. No `eval`, `test`, `candidate` or `benchmark` in its prompt or paths, and no request to list the skills it used.
3. **Grade against the expected results**, from what it produced and which files its transcript shows it opened, not from its own account or from whether the output looks reasonable.
4. **Run judgment twice.** A skill that classifies, judges or picks between options runs at least twice, with the same prompt, on separate fresh agents. A case where the runs disagree is a defect in the skill, even when both answers are defensible: find the missing rule or fact behind it and write it in.
5. **Fix the skill, not the run,** and rerun until it runs clean.

Also, when they apply:

- **A change to an existing skill:** run the same task against the old and new versions, and have one Reviewer (`model-roles`) compare both outputs under neutral labels. A fix written from one bad session tends to overfit it; the comparison shows whether it helps beyond that session.
- **A model-invoked skill:** write a few prompts that should fire it and a few near misses that should not, and tune the description until both sets behave.

A voice or style skill (a personal mode, a tone guide) skips the run: read it with the user and ask whether it reads like them. If you cannot spawn an agent, follow the skill yourself from a new shell, exactly as written, and say so.

## 8. Ship and hand over

- Put the skill where the project keeps skills (`.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `skills/` in a skills repo), and update the index the repo keeps: a README table row, a plugin manifest.
- Ship it in its own change, never inside the task that prompted it, with the `ship-changes` skill if it is installed.
- Reply with what the skill does and how it is invoked, the key design decisions (invocation, what is inline and what is behind a link, what you left out and why), and the validation and cold-run results, including what the cold run made you change.
