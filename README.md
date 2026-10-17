# skills

My agent skills, installable into any repo with the [`skills`](https://github.com/vercel-labs/skills) CLI.

| Skill | What it does |
| --- | --- |
| [`comments`](skills/comments/SKILL.md) | Cut a change's comments to the ones that earn their place: a fresh reviewer judges them against a closed keep list, surprises become renames, constraints become checks. |
| [`create-skill`](skills/create-skill/SKILL.md) | Write or revise a skill: check a skill is the right fix, choose invocation, write the description as the trigger, validate with a script, prove it on a cold agent. |
| [`create-verification-skill`](skills/create-verification-skill/SKILL.md) | Generate a project's `verify-<app>` skill: prove each user-visible change with a throwaway end-to-end test on an isolated instance. Web (Playwright) and macOS (XCUITest, tried on one app) for now. |
| [`glossary`](skills/glossary/SKILL.md) | Keep the project's ubiquitous language in `GLOSSARY.md`: seed it from the code and UI, challenge conflicting terms during work, and point every agent at it. |
| [`model-roles`](skills/model-roles/SKILL.md) | Pick a subagent's model by its role (Scout, Checker, Implementer, Engineer, Investigator, Reviewer), from criteria checked before the spawn. |
| [`orchestrate`](skills/orchestrate/SKILL.md) | Fan work out to subagents: a delegation plan, a role per workstream that sets its model, critical integration. |
| [`ship-changes`](skills/ship-changes/SKILL.md) | Branch, commit, push, and open a PR or a stack of PRs in the project's conventions, then land through GitHub auto-merge. |
| [`validate-idea`](skills/validate-idea/SKILL.md) | Shape a raw product idea into a direction: a draft with stated defaults, a prototype with variants, then an ADR, a spec issue, and slice issues. |

## Install

```bash
# pick skills and agents interactively
npx skills add rigomart/skills

# everything, for Claude Code and Codex, no prompts
npx skills add rigomart/skills --skill '*' -a claude-code -a codex -y

# one skill
npx skills add rigomart/skills --skill ship-changes

# for every project on this machine
npx skills add rigomart/skills -g
```

Pull the latest versions later with `npx skills update`.

## Layout

Each skill is a folder under `skills/` with a `SKILL.md`. Add one by running `npx skills init <name>` from `skills/`.
