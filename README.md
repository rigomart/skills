# skills

My agent skills, installable into any repo with the [`skills`](https://github.com/vercel-labs/skills) CLI.

| Skill | What it does |
| --- | --- |
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
