# skills

My agent skills, installable into any repo with the [`skills`](https://github.com/vercel-labs/skills) CLI.

| Skill | What it does |
| --- | --- |
| [`babysit-pr`](skills/babysit-pr/SKILL.md) | Watch a PR until its checks pass: wait with T3 Code's PR watcher or a bundled `gh` script, fix failures from the PR's own diff, rerun a flake once, then hand it back green for your review. It never merges. Shapes from tstack's [`babysit-pr`](https://github.com/t3dotgg/tstack/tree/main/skills/babysit-pr) and pstack's babysit playbook. |
| [`comments`](skills/comments/SKILL.md) | Cut a change's comments to the ones that earn their place: a fresh checker judges them against a closed keep list, surprises become renames, constraints become checks. |
| [`create-skill`](skills/create-skill/SKILL.md) | Write or revise a skill: check a skill is the right fix, choose invocation, write the description as the trigger, validate with a script, prove it on a cold agent. |
| [`create-verification-skill`](skills/create-verification-skill/SKILL.md) | Generate a project's `verify-<app>` skill: prove each user-visible change in the real app on an isolated instance, with exact checks and one file per feature saying what to prove. Web (agent-browser) and macOS (XCUITest, tried on one app) for now. |
| [`do`](skills/do/SKILL.md) | Run a task through a playbook (design, build, general): the steps go into the task list word for word, skips stay visible, and the playbook owns review rounds and the report. User-invoked as `/do <task>`; the shape follows pstack's [`poteto-mode`](https://github.com/cursor/plugins/tree/main/pstack/skills/poteto-mode). |
| [`file-issue`](skills/file-issue/SKILL.md) | Write and file GitHub issues in the repo's conventions: read its labels and recent issues, search for duplicates, one issue per PR or a spec with sub-issues, a checkable **You see**, terms instead of file paths, and no personal details. |
| [`glossary`](skills/glossary/SKILL.md) | Keep the project's ubiquitous language in `GLOSSARY.md`: seed it from the code and UI, challenge conflicting terms during work, and point every agent at it. |
| [`implement`](skills/implement/SKILL.md) | Settle a change's decisions instead of asking, prove it with before and after evidence, and report it. The `do` playbooks call it for builds and designs. |
| [`model-roles`](skills/model-roles/SKILL.md) | Pick a subagent's model by its role (Runner, Scout, Checker, Implementer, Engineer, Investigator, Reviewer), from criteria checked before the spawn, on Claude or OpenAI models. |
| [`orchestrate`](skills/orchestrate/SKILL.md) | Fan work out to subagents: a delegation plan, a role per workstream that sets its model, critical integration. |
| [`prototype`](skills/prototype/SKILL.md) | Build switchable variants of a screen or behavior next to the current one, check each yourself, and converge with the user over rounds until they pick a direction. Web and terminal for now. |
| [`review-skill`](skills/review-skill/SKILL.md) | Review a skill from its text, its overlap with other skills, and past Claude Code, Codex and Cursor sessions that used it or did its work without it, then propose what to keep, generalize, move or cut. |
| [`ship-changes`](skills/ship-changes/SKILL.md) | Branch, commit, push, and open a PR or a stack of PRs in the project's conventions, with a body template per change type and screenshots attached through `gh` for visible changes, then land through GitHub auto-merge. |

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

`docs/research/` holds notes behind the skills' design. It has no `SKILL.md`, so `npx skills` never installs it.
