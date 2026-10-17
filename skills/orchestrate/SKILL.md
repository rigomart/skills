---
name: orchestrate
description: Orchestrate substantial work by delegating bounded workstreams to subagents while the main agent owns judgment, coordination, integration, and user collaboration. Gives each subagent a role, which sets its model, through the model-roles skill. Use only when the user explicitly asks for it, by name or by asking for subagents, delegation, parallel agents, fanning out, or orchestration.
---

# Orchestrate

You are the lead orchestrator. The user asked for the work to be **fanned out to subagents**. Doing the task solo defeats the purpose of the skill and counts as failing to follow it.

## Non-negotiables

While this skill is active, these rules override your default habits:

1. **Delegate heavy work by default.** Every meaningfully sized workstream goes to a subagent unless you can state, in one sentence, why delegation is worse: a hard sequential dependency on an unfinished result, or coordination cost exceeding the work. "I can do it faster myself" is not a valid reason for heavy work; context isolation and parallelism are the point. Quick one-off actions are yours to do directly (see What you do yourself). Do not spawn an agent to read one file or fix one line.
2. **Choose every subagent's model on purpose.** Give every workstream a role (Step 2) and set the role's model on every spawn.
3. **Launch independent agents in parallel, in a single message.** Serial spawning of independent work is a failure mode. Batch all independent spawn calls into one response so they run concurrently.
4. **Plan before the first spawn.** Before any agent launches, show the user a short delegation plan (Step 1). Quick reads to inform the plan are fine. No plan and you will drift into doing everything solo.

Anti-patterns this skill exists to prevent. If you catch yourself in one, stop and correct:

- Reading the skill, then grinding through the task alone with Read, Grep, and Edit.
- Spawning a single agent for "the whole task". That only moves the work; it does not orchestrate it.
- Leaving the model unset because "the default is probably fine". The default is often your own session's model, which may be the most expensive one.
- Spawning one agent, waiting, spawning the next, waiting, for work that was independent.
- Delegating everything and idling instead of doing integration, verification, and critical-path work yourself.
- The inverse over-correction: spawning an agent for a 30-second action a single tool call would finish.

## What you do yourself

Delegation applies to workstreams, not every keystroke. Handle these directly, without spawning:

- one-off reads, quick greps, and single lookups needed for your own orchestration decisions;
- quick edits: a one-line fix, a rename, a config tweak, deleting an obsolete file;
- glue work during integration: small adjustments that stitch subagent results together;
- verification commands (the test suite once, a build, a lint pass) whose output you need to judge personally.

The line is effort and context cost. A bounded chunk of work that needs sustained focus, produces noisy intermediate output, or benefits from an independent perspective gets delegated. An atomic action you would finish in a call or two, you just do.

## Step 1: Write the delegation plan

Before the first spawn, output a compact plan the user can see:

| Workstream | Agent type | Role | Provider | Wave |
| --- | --- | --- | --- | --- |
| e.g. run the full end-to-end suite and report each failing test's name and message verbatim | general-purpose | Runner | session | 1 |
| e.g. find every place that writes to the orders table, through the ORM and raw SQL | Explore | Scout | session | 1 |
| e.g. find why sessions drop after a deploy | general-purpose | Investigator | session | 1 |
| e.g. implement the API slice (`src/api/*` only), mirroring the users slice | general-purpose | Implementer | session | 2 |
| e.g. migrate the sessions table and its readers | general-purpose | Engineer | session | 2 |
| e.g. adversarial security review of the integrated diff | general-purpose | Reviewer | other | 3 |

Rules for the plan:

- Split the task into bounded workstreams with one owner each; give files or modules that overlap to a single agent.
- Group independent workstreams into waves; everything in a wave launches in one message.
- Name what **you** keep: requirements interpretation, user decisions, integration, verification, final synthesis.
- 2 to 3 agents for a moderate task, more for genuinely wide work. One agent is almost never a plan.
- When the session's model caps a role's model, or a review cannot go to the other provider (Step 2), say so under the table.

## Step 2: Give each workstream a role

Call the Skill tool with `model-roles`. It defines the roles, how to pick one from criteria checked before the spawn, the model each role runs on, and how to set it. Read it before you write the plan, and put each workstream's role in it.

If `model-roles` is not installed, say so under the plan and run every workstream on your session's model.

## Step 3: Launch and keep working

1. Launch wave 1 in a single message with one spawn call per workstream.
2. While agents run, do orchestrator work: resolve requirements, inspect shared context, prepare integration, handle the critical path. Do not idle, and do not duplicate a search you already delegated.
3. Agents may run in the background and notify you when they finish. Do not poll them, and never report or predict a result before its notification arrives. If the user asks in the meantime, say it is still running.
4. When results arrive, steer: stop redundant or drifting agents, continue an existing agent (in Claude Code, `SendMessage`) instead of respawning when its context is still useful, and launch the next wave.
5. Integrate results into one coherent solution. Resolve contradictions with evidence, a targeted follow-up, or an independent tie-breaker agent.
6. Verify claims, diffs, and tests yourself, as deeply as the risk calls for.

For write-heavy waves, give each agent exclusive ownership of files or modules. Never assign concurrent edits to overlapping areas unless the platform gives each agent an isolated workspace (in Claude Code, `isolation: "worktree"`) and you have a deliberate merge plan.

## Write bounded delegation prompts

Give each subagent enough context to work alone, without the full conversation. Include:

- a single concrete objective and why it matters;
- exact scope, relevant paths or sources, and explicit exclusions;
- constraints and settled decisions it must preserve;
- whether it may edit or must stay read-only (tell read-only agents so explicitly);
- the deliverable: evidence, tests, file changes, or a structured summary of concise findings, not raw logs;
- what it must not decide without escalating to you.

Each review round is a fresh spawn. Its prompt carries the original brief, the earlier findings, the responses to them, and any objection still unresolved.

## Decision boundaries

Make routine, reversible, low-impact decisions yourself: search strategy, agent assignment, role, test selection, small implementation details consistent with existing patterns, retrying a failed subtask.

Surface decisions to the user when they materially affect product behavior, scope, architecture, security or privacy posture, external systems, irreversible data, cost, or a stated tradeoff the user should own. Route all subagent escalations through yourself; do not let subagents ask the user things you can resolve from established context.

## Integrate critically

Treat subagent output as evidence, not truth.

- Inspect important claims and the resulting diffs.
- Reconcile the work against repository and task instructions.
- Run required verification after integrating changes.
- When an unbiased check matters, use an independent reviewer and do not hint at the conclusion you expect.
- Retry or reassign incomplete subtasks; do not silently fill critical gaps with assumptions.
- Return one unified answer: completed work, evidence, unresolved risk, and decisions that need the user.

You remain accountable for the outcome even when nearly all supporting work was delegated.

## Fallback: constrained environments

If the environment has no subagent tool, or spawning is disabled, continue as a single agent, say so briefly, and do not pretend delegation occurred. Assume subagents cannot spawn their own subagents.
