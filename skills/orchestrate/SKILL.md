---
name: orchestrate
description: Orchestrate substantial work by delegating bounded workstreams to subagents while the main agent owns judgment, coordination, integration, and user collaboration. Picks each subagent's model from three tiers with explicit criteria and keeps every run on one model vendor. Use only when the user explicitly asks for it, by name or by asking for subagents, delegation, parallel agents, fanning out, or orchestration.
---

# Orchestrate

You are the lead orchestrator. The user asked for the work to be **fanned out to subagents**. Doing the task solo defeats the purpose of the skill and counts as failing to follow it.

## Non-negotiables

While this skill is active, these rules override your default habits:

1. **Delegate heavy work by default.** Every meaningfully sized workstream goes to a subagent unless you can state, in one sentence, why delegation is worse: a hard sequential dependency on an unfinished result, or coordination cost exceeding the work. "I can do it faster myself" is not a valid reason for heavy work; context isolation and parallelism are the point. Quick one-off actions are yours to do directly (see What you do yourself). Do not spawn an agent to read one file or fix one line.
2. **Choose every subagent's model on purpose.** Pick a tier with the criteria in Step 2. Set the model on every spawn, except for an agent type whose definition already picks one (see Step 2).
3. **One vendor per run.** Every subagent runs on the same vendor's models as your own session: Claude subagents from a Claude session, OpenAI subagents from a Codex session. Do not mix them, even when a tool, a CLI on the machine (`codex exec`, `claude -p`, `gemini`), or another skill's configuration offers agents from another vendor.
4. **Launch independent agents in parallel, in a single message.** Serial spawning of independent work is a failure mode. Batch all independent spawn calls into one response so they run concurrently.
5. **Plan before the first spawn.** Before any agent launches, show the user a short delegation plan (Step 1). Quick reads to inform the plan are fine. No plan and you will drift into doing everything solo.

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

| Workstream | Agent type | Tier | Wave |
| --- | --- | --- | --- |
| e.g. list every call site of the old API | Explore | Light | 1 |
| e.g. explain how the auth flow in `src/auth` issues tokens | general-purpose | Standard | 1 |
| e.g. implement the API slice (`src/api/*` only) | general-purpose | Standard | 2 |
| e.g. find why sessions drop after a deploy | general-purpose | Deep | 2 |
| e.g. adversarial security review of the integrated diff | general-purpose | Deep | 3 |

Rules for the plan:

- Split the task into bounded workstreams with one owner each; give files or modules that overlap to a single agent.
- Group independent workstreams into waves; everything in a wave launches in one message.
- Name what **you** keep: requirements interpretation, user decisions, integration, verification, final synthesis.
- 2 to 3 agents for a moderate task, more for genuinely wide work. One agent is almost never a plan.
- When the session's model caps a tier (Step 2), say so under the table.

## Step 2: Pick the model tier

Subagents use three tiers. Each maps to a model family per vendor. Use the family name; the version changes over time and the spawn tool lists what is current.

| Tier | Claude | OpenAI | Reasoning effort |
| --- | --- | --- | --- |
| Light | Haiku | Luna | low |
| Standard | Sonnet | Terra | medium |
| Deep | Opus | Sol | high |

The frontier families (Claude Fable, OpenAI Astra) are not a subagent tier. The user chooses them for their own session; use one for a subagent only when the user asks for it on that workstream.

### Criteria

Decide in this order, and stop at the first match:

**1. Deep, if any of these is true:**

- Something is not settled: the requirements, the root cause, or the design.
- The work crosses module boundaries or changes a contract, schema, auth, permission, or stored data.
- You could not check the output cheaply and would have to take it on trust: root-cause analysis, architecture, design options, synthesis of conflicting results.
- It is an independent or adversarial review whose verdict you will rely on.
- A mistake is expensive to unwind: a migration, a wide refactor, a change other workstreams build on.
- A lower tier already returned a weak result on this same workstream.

**2. Light, if all of these are true:**

- The answer is found, not reasoned out: locate, list, count, extract, or run a known command and report its output.
- The prompt states what done looks like, and you can confirm the result at a glance.
- It edits nothing, or the edit is spelled out exactly: a given rename, a given text replacement, a given list of files.
- A wrong result is obvious and cheap to redo.

Examples: every call site of a function, the files that import a module, the failing tests from a known suite with their messages, the fields pulled from a log.

**3. Standard, for everything else:** real work with judgment, inside clear walls.

- The scope is fixed (known files or modules) and the spec is settled.
- An existing pattern in the codebase shows the way.
- A test, a typecheck, or a short read of the diff will show whether it worked.

Examples: an implementation slice that mirrors an existing one, tests for behavior already specified, a summary of how one module works, a set of type or lint errors to fix, focused documentation research on one question.

### Caps and adjustments

- **Never above your own session.** A subagent's tier never exceeds the model your session runs on. On a Sonnet or Terra session, Deep work goes to that model, and the plan says so.
- **Upgrade, never downgrade mid-workstream.** When an agent returns weak evidence, misses an ambiguity, or fails, first sharpen its prompt; if the prompt was sound, rerun it one tier up. Do not drop a tier to save cost on a retry.
- **Missing tier.** If a vendor has no current model in a tier (an older generation is not current), use the tier above it at that tier's reasoning effort.
- **Reasoning effort.** When the spawn tool exposes effort, set it from the table. Raise Standard to high for a workstream that is close to Deep.

### Setting the model on a spawn

Read the spawn tool's schema for the accepted model values and pick the one in the tier's family. Never invent an identifier or pass a name from another vendor.

Leave the model unset only for an agent type whose definition picks its own: a custom agent with `model:` in its definition (`.claude/agents/*.md`, `~/.claude/agents/*.md`, or the platform's equivalent), or one the user configured. That choice was made on purpose. If you cannot tell whether a type defines a model, set it. Unset otherwise means your session's model, which often skips the tiers entirely.

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

## Decision boundaries

Make routine, reversible, low-impact decisions yourself: search strategy, agent assignment, tier, test selection, small implementation details consistent with existing patterns, retrying a failed subtask.

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

If the environment has no subagent tool, or spawning is disabled, continue as a single agent, say so briefly, and do not pretend delegation occurred. If the spawn tool has no model parameter, delegate anyway and let the platform choose; Step 2 applies only where a model can be set. Assume subagents cannot spawn their own subagents.
