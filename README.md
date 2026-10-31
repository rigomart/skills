# skills

My agent skills for Claude Code, Codex and other coding agents. Install them into any repo with the [`skills`](https://github.com/vercel-labs/skills) CLI.

Most skills load on their own when a task matches their description. The ones marked **user-invoked** run only when you type them.

## Skills

### Run a task

- [`do`](skills/do/SKILL.md) (**user-invoked**, `/do <task>`): runs a task through a playbook: `build` for one change, `fleet` for several changes that each ship as their own PR, `research` for questions that need evidence gathered, and `general` for everything else. The playbook's steps go into the task list word for word, skipped steps stay visible with a reason, and the playbook owns review rounds and the final report.
- [`implement`](skills/implement/SKILL.md): settles a change's decisions instead of asking, proves it with before and after evidence, and reports it. The `do` build playbook calls it for every change.
- [`research`](skills/research/SKILL.md): answers a question that needs evidence gathered first. Pins the decision and constraints, starts from your own repos and machine, keeps git-excluded notes with how far each source was read, tests the deciding claim, and reports a verdict without changing anything. The `do` research playbook calls it.
- [`prototype`](skills/prototype/SKILL.md): builds switchable variants of a screen or behavior next to the current one, checks each, and converges with you over rounds until you pick a direction. Web and terminal for now.

### Ship and track work

- [`ship-changes`](skills/ship-changes/SKILL.md): branches, commits, pushes and opens a PR or a stack of PRs in the project's conventions. Picks a body template by change type, attaches screenshots of visible changes through `gh`, and lands through GitHub auto-merge.
- [`babysit-pr`](skills/babysit-pr/SKILL.md): watches a PR until its checks pass, using T3 Code's PR watcher or a bundled `gh` script. Fixes failures caused by the PR's own diff, reruns a flake once, and hands the PR back green for your review. It never merges.
- [`file-issue`](skills/file-issue/SKILL.md): writes and files GitHub issues in the repo's conventions. Reads its labels and recent issues, searches for duplicates, and writes one issue per PR or a spec with sub-issues, each with a checkable outcome.

### Work with subagents

- [`subagents`](skills/subagents/SKILL.md): decides what goes to a subagent and what stays with you, picks its model from its role (Runner, Scout, Checker, Implementer, Engineer, Investigator, Reviewer) on Claude or OpenAI models, sets the brief and the limits on agents running at once, and checks what comes back.

### Keep code and language clean

- [`comments`](skills/comments/SKILL.md): cuts a change's comments to the ones that earn their place. A fresh checker judges them against a closed keep list; surprises become renames and constraints become checks.
- [`glossary`](skills/glossary/SKILL.md): keeps the project's terminology in `GLOSSARY.md`, one name per concept. Seeds it from the code and UI, challenges conflicting terms during work, and points every agent at it.

### Write and test skills

- [`author-skills`](skills/author-skills/SKILL.md): writes, revises and reviews skills and playbooks. Holds the design rules (one owner per rule, subtract before you add, encode what must hold in structure, a repeat before a rule, process in playbooks and judgment in skills, references to whole files only) and the standard for descriptions, layout and prose. Writing checks a skill is the right fix, validates it with a script and proves it on a cold agent. Reviewing reads the text, its overlap with other skills, and past Claude Code, Codex and Cursor sessions with and without it, then proposes what to keep, generalize, move or cut.
- [`create-verification-skill`](skills/create-verification-skill/SKILL.md) (**user-invoked**): generates a project's `verify-<app>` skill, so agents prove each user-visible change in the real app on an isolated instance. Web (agent-browser) and macOS (XCUITest) for now.

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

## Repo layout

Each skill is a folder under `skills/` with a `SKILL.md`. Add one by running `npx skills init <name>` from `skills/`.

Playbooks (`skills/do/playbooks/`) name the skills they use, never the other way around: a skill stays usable on its own, without `do`.

`docs/research/` holds the notes behind the skills' design. It has no `SKILL.md`, so `npx skills` never installs it.
