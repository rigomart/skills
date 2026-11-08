---
name: subagents
description: Decide what goes to a subagent, set its role and model, brief it, and check what it returns. Use before every subagent spawn, even when told to use subagents, parallel agents or orchestration, and when a skill names a role (Reviewer, Checker).
---

# Subagents

You decide what goes to an agent, its role, its model and its brief, and you own the result: the requirements, the user's decisions, integration, verification and the final answer. Each agent owns its workstream.

## What earns an agent

A bounded workstream goes to an agent when at least one of these holds:

- it can run while other work runs;
- its output is too long or noisy for your context: a full test suite, a wide search, a long log;
- it needs a view independent of yours: a review, a tie-break;
- it needs sustained focus on an area you don't otherwise need in context.

The test sets the bar when the ask is conditional: "if needed", "if convenient" or "as needed" delegates only the workstreams that gain clearly, and a plan of one agent, or none, is fine. When the user asks for subagents outright, the ask is the reason: find the split that works (see **Split the work**) instead of judging the work too small or too entangled. Either way, name what you kept and why in a line.

Wrong: "orchestrate this if needed" on a small app, and four Engineers, a browser QA agent and two review waves start.
Right: two Engineers for the parallel halves and a Reviewer on the result; the lead does the QA.

Wrong: "use parallel agents" on three edits that share two files, and the lead does them all because they overlap.
Right: the lead writes the shared helper first, then one agent per file.

## Roles

Every subagent gets a role before it is spawned, and the role alone sets its model. When work turns out harder than its role, it was another role all along: move it there.

| Role | Use when |
| --- | --- |
| Runner | It runs a command given word for word, or copies given fields out of given files or logs, and reports the result verbatim, with nothing to search, choose or summarize. Before you use its result, check it yourself: rerun one reported failure, or read a reported line in the source. Its own exit code or summary is the claim, not the check. Only for output too long or noisy to pull into your own context: a full test suite, a large log. |
| Scout | It finds what a grep cannot settle: matches you can only judge by reading the code (calls through aliases or dynamic dispatch, writes through an ORM and raw SQL, every place a value flows), over more code than you want in your context. The answer is found, not reasoned out. |
| Checker | It applies a closed list of rules to given work, and you verify each finding by reading it. |
| Implementer | It edits, and all of these hold: the spec is complete, an existing pattern shows the way, it stays inside known files, and a test or typecheck shows whether it worked. |
| Engineer | It edits, and any Implementer condition fails: the spec has gaps or needs nuance, the change crosses modules or touches a contract, schema, auth or stored data, or a mistake is expensive to unwind. |
| Investigator | The answer is not known yet: a root cause, design options, architecture, open research, how an unfamiliar part of the system works. |
| Reviewer | It gives a verdict you will rely on without redoing the work: open-ended code review, adversarial or security review, comparing options, breaking a tie. |

Pick it by these, in order:

- **It edits files:** Implementer when every Implementer condition holds, otherwise Engineer. A condition you cannot confirm from the brief or the code counts as failing.
- **It only reports:** Runner, Scout, Checker, Investigator or Reviewer, by the table. A search that needs reading the code is Scout work, never Runner work: a small model fails by leaving things out, and a list with a gap looks complete.
- **It fits two roles:** take the one with the larger model.
- **It fits no role clearly:** Engineer if it edits, Investigator if it does not.
- **It spans two roles** (an unsettled design, then building it): make it two subagents, an Investigator first, then an Implementer or Engineer with the settled result.

## Models

Each role has a tier, and the tier sets the model:

| Role | Tier |
| --- | --- |
| Runner | small |
| Scout, Checker, Implementer | mid |
| Engineer, Investigator, Reviewer | large |

Two providers' families, as examples of the mapping:

| Tier | Claude | OpenAI |
| --- | --- | --- |
| small | Haiku | Luna |
| mid | Sonnet | Sol |
| large | Opus | Sol |

- **Newest in the tier.** Read the spawn tool's models and take the newest one in the tier; never an older one that is still listed, the tool's default, or the first entry.
- **Unknown provider or missing tier.** Sort the models the tool offers into small, mid and large by what the provider says of their size or cost. When a role's tier is not offered, use the next larger one; when there is none, the largest offered, and say so. When the spawn tool cannot set a model at all, spawn anyway and say so.
- **Your session's provider.** Subagents run on the provider your session runs on, except the Reviewer.
- **The Reviewer crosses over.** It runs on another provider from the one that did the work, so its verdict is independent. When the environment cannot spawn on another provider, it runs on the same one, and you say so. Reach another provider only through a tool built for subagents on it, never by shelling out to a CLI (`codex exec`, `claude -p`).
- **Frontier only on request.** A tier above large (such as Fable or Astra) runs a subagent only when the user asks for one on that work.
- **Effort.** Where the spawn tool takes an effort setting, follow the session's effort policy, from the harness or the user. Without one, leave the tool's default for every role.
- **Never above your session.** When your session runs on a mid-size model (such as Sonnet), roles that call for a larger one run at mid size, and you say so ("the Reviewer ran at mid size, capped at this session's"). A small session (such as Haiku or Luna) runs everything at small size.
- **A failed run is reclassified.** When a run fails your check, sharpen the prompt first. When a sound prompt fails twice, the work met another role's criteria: rerun it under that role. When that role runs the same model (Sol covers both mid and large roles), rerun it on another provider, or do the work yourself. A retry never moves to a smaller model.
- **Configured models win.** Leave the model unset for an agent type whose definition sets one (such as `model:` in `.claude/agents/*.md`), one the user configured, or where the harness's rules say not to set it. Otherwise set it whenever the tool and session allow: unset usually means your session's model, which skips the role.

## Split the work

- One owner per workstream. Files or modules two workstreams would both edit go to one agent, unless each agent gets its own worktree and you have a plan for merging them.
- Independent workstreams start together, in one message. One that needs another's result starts after it reports, unless you write the contract it needs first (a type, a schema, an API shape) and give it to both.

## Spawn

- **Know your tools first.** Before you pick roles, see which spawn tools the session offers: the native subagent tool, any delegate tool the harness adds, and whether one reaches another provider for the Reviewer. Use each the way the harness's own instructions say.
- **Task list before spawning.** With more than one agent, create one task per workstream, naming its role, before the first spawn, and mark each as its agent reports. Use the session's task-list tool (`TaskCreate` in Claude Code); when it is deferred, load it first. Without one, list the workstreams in one line each.

  Wrong: the skill loads, and two Scouts start in the next message with the task list empty.
  Right: `TaskCreate` for "Scout: callers in api/" and "Scout: callers in web/", then both spawns in one message.
- **Keep working while they run.** When you have work of your own to do meanwhile, start agents in the background where the harness supports it, and take each result through its completion mechanism: a notification, or a wait tool. Don't poll, and never report or predict a result before it arrives.
- **Continue, don't respawn.** Rework, fixes and follow-ups go to the agent that holds the context, continued, not to a fresh one.
- **Limits.** At most three agents that build, test or drive an app at once, and at most one that drives a browser or the app, unless the user sets other limits. Read-only agents don't count. Reviewers start no dev server, browser or full test suite. An agent that starts a long-running process stops it before it reports.

## Brief

Write each brief to stand alone, without relying on the conversation: some agents start with none of it. Give it:

- its role, one objective and why it matters;
- exact scope: paths, sources, and what is out of bounds;
- the settled decisions it must keep, and what it must ask you before deciding;
- whether it may edit, or must stay read-only;
- the limits above that apply to it;
- the deliverable: findings, evidence, or file changes. An agent in its own worktree commits on a named branch and reports the branch and its head.

## Integrate

Treat each agent's output as evidence, not truth.

- Read the diffs, rerun the checks yourself, and confirm each claim the result rests on.
- Bring a worktree agent's work in by its branch (`git fetch`, then merge or cherry-pick), and run the checks in your own tree, where dependencies match.
- A fix to an agent's change, from a review or a failed check, goes back to that agent. You make only the glue between results.
- When an unbiased check matters, spawn a Reviewer with no hint of the verdict you expect. Resolve contradictions with evidence, a targeted follow-up or a tie-breaking agent.
- Agents' questions come to you. Answer what the established context settles, and take the rest to the user.
- Retry or reassign an incomplete workstream. Never fill a critical gap with an assumption.
