# Write or revise a skill

You draft the skill, cut it, and prove it before you hand it over. The design rules and the standard in `SKILL.md` apply to every line.

## 1. Check that a skill is the fix

Apply **A repeat before a rule**, **Encode in structure** and **Subtract before you add** to the fix you have in mind. When the fix is structural, ship only the structural fix. A skill is right for workflows and judgment that no check can carry.

- **Extend before adding.** Search the installed skills, the project's and the user's, for one that covers this case, and extend it. A new skill earns its place with a trigger of its own, or when another skill must reach it.
- **Process or judgment.** The order of work across skills for one kind of request is a playbook, in the `do` skill's `playbooks/` folder.

Done when you can name the workflow or failure, the evidence for it, and why no check or existing skill covers it. If one does, say so and propose that instead.

## 2. Gather from evidence

Build the content from what happened and what exists, not from general knowledge:

- The conversation or transcript where the workflow ran, and every correction the user made in it. After a review, the evidence file it wrote.
- The repo: scripts, config, conventions, `AGENTS.md` or `CLAUDE.md`, the project's glossary.
- Prior art: skills that do something close. For a playbook, the other playbooks, and the real requests `scripts/sessions.sh find do` turns up with terms from the request.
- For a rewrite, the skill itself, its references and its git history. Keep what the history shows was learned.

Ask the user only what you cannot read or run, each question with your default. Every command, path and name the skill gives comes from the repo and has been run. No placeholders.

## 3. Write

Choose the invocation, write the description, lay out the body and write the prose, all to the standard in `SKILL.md`. Then validate as it says.

## 4. Prove it cold

A skill that was never followed is a draft. Prove it with a fresh agent:

1. **Write the expected results** for each part of the task before the run: the action per planted case, the role per item, the output a step should produce. Keep them out of the agent's prompt and paths.
2. **Run a blind agent.** Give a fresh agent only the repo and an organic task, written the way a user would type it ("prove that X shows Y after Z", not "test this skill"), on the model the skill normally runs on. After a review, the `similar` sessions' first prompts in its evidence file are organic tasks. No `eval`, `test`, `candidate` or `benchmark` in its prompt or paths, and no request to list the skills it used.
3. **Grade against the expected results**, from what it produced and which files its transcript shows it opened, not from its own account or from whether the output looks reasonable.
4. **Run judgment twice.** A skill that classifies, judges or picks between options runs at least twice, with the same prompt, on separate fresh agents. A case where the runs disagree is a defect in the skill, even when both answers are defensible: find the missing rule or fact behind it and write it in.
5. **Fix the skill, not the run,** and rerun until it runs clean.

Also, when they apply:

- **A change to an existing skill:** run the same task against the old and new versions, and have one Reviewer (`model-roles`) compare both outputs under neutral labels. The comparison shows whether the fix helps beyond the session that prompted it.
- **A model-invoked skill:** write a few prompts that should fire it and a few near misses that should not, and tune the description until both sets behave.
- **A playbook:** write 10 to 15 requests in users' words, for it and for its neighbors, with the expected playbook for each. Two fresh agents, given only the `do` skill and its playbooks, pick one per request. A request where they disagree, or both miss, is a defect in the table.

A voice or style skill (a personal mode, a tone guide) skips the run: read it with the user and ask whether it reads like them. If you cannot spawn an agent, follow the skill yourself from a new shell, exactly as written, and say so.

## 5. Ship and hand over

- Put the skill where the project keeps skills (`.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `skills/` in a skills repo), and update the index the repo keeps: a README table row, a plugin manifest.
- Ship it in its own change, never inside the task that prompted it, with the `ship-changes` skill if it is installed.
- Reply with what the skill does and how it is invoked, the key design decisions (invocation, what is inline and what is behind a link, what you left out and why), the design rules you applied and the decision each changed, and the validation and cold-run results, including what the cold run made you change.
