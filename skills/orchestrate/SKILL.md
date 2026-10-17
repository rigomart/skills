---
name: orchestrate
description: Orchestrate substantial work by delegating bounded workstreams to subagents while the main agent owns judgment, coordination, integration, and user collaboration. Runs each subagent on the strongest model by default and on a cheaper one only when explicit criteria hold, using only the models in its model list. Use only when the user explicitly asks for it, by name or by asking for subagents, delegation, parallel agents, fanning out, or orchestration.
---

# Orchestrate

You are the lead orchestrator. The user asked for the work to be **fanned out to subagents**. Doing the task solo defeats the purpose of the skill and counts as failing to follow it.

## Non-negotiables

While this skill is active, these rules override your default habits:

1. **Delegate heavy work by default.** Every meaningfully sized workstream goes to a subagent unless you can state, in one sentence, why delegation is worse: a hard sequential dependency on an unfinished result, or coordination cost exceeding the work. "I can do it faster myself" is not a valid reason for heavy work; context isolation and parallelism are the point. Quick one-off actions are yours to do directly (see What you do yourself). Do not spawn an agent to read one file or fix one line.
2. **Choose every subagent's model on purpose.** Use the default tier unless the criteria in Step 2 allow a lower one. Set the model on every spawn, except for an agent type whose definition already picks one (see Step 2).
3. **Only the listed models.** Every subagent runs on a model from [references/models.md](references/models.md). Do not route work to any other model, even when a tool, a CLI on the machine, or another skill's configuration offers one.
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

| Workstream | Agent type | Tier | Vendor | Wave |
| --- | --- | --- | --- | --- |
| e.g. run `pnpm test` and report each failing test's name and message verbatim | general-purpose | Light | session | 1 |
| e.g. list every call site of the old API | Explore | Standard | session | 1 |
| e.g. explain how the auth flow in `src/auth` issues tokens | general-purpose | Deep | session | 1 |
| e.g. implement the API slice (`src/api/*` only), mirroring the users slice | general-purpose | Standard | session | 2 |
| e.g. find why sessions drop after a deploy | general-purpose | Deep | session | 2 |
| e.g. adversarial security review of the integrated diff | general-purpose | Deep | other | 3 |

Rules for the plan:

- Split the task into bounded workstreams with one owner each; give files or modules that overlap to a single agent.
- Group independent workstreams into waves; everything in a wave launches in one message.
- Name what **you** keep: requirements interpretation, user decisions, integration, verification, final synthesis.
- 2 to 3 agents for a moderate task, more for genuinely wide work. One agent is almost never a plan.
- When the session's model caps a tier, or reviews cannot go to another vendor (Step 2), say so under the table.

## Step 2: Pick the model tier

Subagents use three tiers: **Deep**, the default, then **Standard** and **Light**. [references/models.md](references/models.md) maps each tier to a model for each vendor and says how to set it on a spawn. Read it before the first spawn.

### Criteria

Decide in this order, and stop at the first match. When in doubt between two tiers, pick the higher one.

**1. Light, only if the task is one of these shapes:**

- Run a command given word for word and report its exit code and the output you asked for, verbatim: each failing test's name and message, the build errors, the lint warnings.
- Copy given fields out of given files or logs, verbatim.
- Apply an edit given exactly (the old text and the new text) to a given list of files.

**and all of these are true:**

- The prompt names every input: the command, the files, the fields, the edit. The agent searches for nothing and chooses nothing.
- The output is copied, not written: no summary, diagnosis, ranking, or opinion on what matters.
- You will check the result mechanically before relying on it: the exit code, a rerun, `git diff` against the given edit, or a spot check against the source.
- It is not a "find every X" search. A small model fails by leaving things out, and a list with a gap looks complete.
- No earlier Light run on this workstream came back wrong or incomplete.

**2. Standard, if all of these are true:**

- The scope is fixed (known files or modules) and the spec is settled.
- The answer is found, not reasoned out (locate, list, extract, run a known command), or an existing pattern in the codebase shows the way.
- You can check the result cheaply: at a glance, with a test or a typecheck, or with a short read of the diff.
- It changes no contract, schema, auth, permission, or stored data, and no other workstream builds on it before you check it.
- It is not a review whose verdict you will rely on.
- No earlier Standard run returned a weak result on this same workstream.

Examples: every call site of a function, an implementation slice that mirrors an existing one, tests for behavior already specified, a set of type or lint errors to fix, focused documentation research on one question.

**3. Deep, for everything else.** This is the default: unsettled requirements or designs, root-cause analysis, cross-module changes, migrations, reviews you rely on, synthesis of conflicting results, and anything that missed a criterion above.

### Pick the vendor

The tier picks the model family; the vendor is a separate choice. Default to your session's vendor, except for reviews: run every review on a different vendor from the work it reviews. That covers implement-then-review iterations, adversarial and security reviews, and tie-breakers between conflicting results. A second vendor misses different things. [references/models.md](references/models.md) names the default pairing.

Each review round is a fresh spawn that carries the original brief, the earlier findings, the responses, and any unresolved objections.

Spawn agents on another vendor with whatever tools the harness offers. If it offers none, see the fallback.

### Caps and adjustments

- **Never above your own session.** A subagent's tier never exceeds your session's tier, on any vendor. When your session runs on a lower tier's model, work above that tier goes to your session's model, and the plan says so.
- **Upgrade, never downgrade mid-workstream.** When an agent returns weak evidence, misses an ambiguity, or fails, first sharpen its prompt; if the prompt was sound, rerun it one tier up. If the tier above runs the same model, rerun it on the other vendor at that tier, or take the workstream yourself. Do not drop a tier to save cost on a retry.
- **Missing tier.** If a tier has no current model, use the tier above it.
- **Reasoning effort is always high, never higher.** Set it on every spawn where the tool allows it, whatever the tier and vendor. The tier picks the model; it never changes the effort.

### Setting the model on a spawn

Read the spawn tool's schema for the accepted model values and pick the newest version of the tier's family. Never invent an identifier.

Leave the model unset only for an agent type whose definition picks its own, or one the user configured. That choice was made on purpose. If you cannot tell whether a type defines a model, set it. Unset otherwise usually means your session's model, which skips the tiers entirely.

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

If the environment has no subagent tool, or spawning is disabled, continue as a single agent, say so briefly, and do not pretend delegation occurred. If the spawn tool has no model parameter, or the model list has none of the models it accepts, delegate anyway and let the platform choose; Step 2 applies only where a listed model can be set. If the harness cannot spawn agents on another vendor, run every workstream on your session's vendor, reviews included, and say so in the plan. Assume subagents cannot spawn their own subagents.
