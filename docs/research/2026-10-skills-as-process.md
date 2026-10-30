# Skills as process: what fails, what the evidence says, what we're trying

October 2026. Why the skills in this repo moved from "each skill carries its own process" to a gateway with playbooks.

## The problem

Skills carry judgment well: how to prove a change, how to brief a reviewer. They carry process badly: "always do X", "then use skill Y", "stop after N rounds", "report in this shape". Reviewing past sessions against the skill text (with the `review-skill` skill) turned up five recurring failure types:

1. **A skill doesn't fire when the request's wording misses its description.** "The X skill should never do Y" reads as an edit to a skill, but it fires neither a review skill nor an authoring skill whose descriptions say "review, audit or improve".
2. **A clear mandatory step inside a loaded skill gets skipped.** A "show the plan before the first subagent" step was skipped in most sessions where the skill loaded.
3. **Routing between skills doesn't happen.** Work started through one skill never loaded the skill that owns the next part ("big work runs through `orchestrate`", but `orchestrate` never hands back to `implement`).
4. **Loop control written as prose fails both ways.** Fixes from a review go in without a re-review, and other review loops run on with no stopping point.
5. **Two skills prescribe conflicting report formats** when they load in the same session.

Newer models did not make these go away.

## Evidence on skill and instruction reliability

Measured:

- **Vercel, "AGENTS.md outperforms skills in our agent evals"** (2026-01-27, https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals). Next.js tasks; model and sample size not disclosed. Baseline 53%. Skill available: 53%, never invoked in 56% of cases. Skill plus an explicit "use the skill" instruction: 79%, triggering at 95% or more. An 8 KB docs index placed in `AGENTS.md`: 100%. Vendor post; the task is knowledge retrieval, not process.
- **Scott Spence, skill activation in Claude Code** (2026-02-08, https://scottspence.com/posts/measuring-claude-code-skill-activation-with-sandboxed-evals). Sonnet 4.5, 22 prompts × 2 runs in sandboxes. No hook: 50–55% activation. A "forced-eval" `UserPromptSubmit` hook (state yes/no per skill, then load it): 100%. Small n, one model. A follow-up (2026-03-22) saw Claude start walking past the hook's injected text: "if something is truly mandatory, don't rely on one mechanism."
- **IFScale** (arXiv 2507.11538, NeurIPS 2025). Accuracy falls as instruction count grows (Opus 4 at 44.6% with 500 keyword instructions). Earlier instructions are followed better; omission is the main error.
- **"LLMs Get Lost in Multi-Turn Conversation"** (arXiv 2505.06120, ICLR 2026). A 39% average drop from single-turn to multi-turn, mostly unreliability.
- **"Evaluating AGENTS.md"** (arXiv 2602.11988, ETH, ICLR 2026). Context files did not generally raise success rates and cost over 20% more. Their instructions were followed; unnecessary requirements made tasks harder.
- **SkillsBench** (arXiv 2602.12670). Curated skills +16.4 points on average; self-generated skills −1.3.
- **"The Regression Tax"** (arXiv 2607.22520, preprint, ~6,000 runs). Skills cause regressions on tasks the agent would otherwise solve: behavior shifts just from a skill being listed, and a written procedure displaces the agent's own checks.

Vendor guidance:

- **Claude Code best practices** (https://code.claude.com/docs/en/best-practices): prompts, `CLAUDE.md` and model-invoked skills are non-deterministic; hooks, deny rules and Stop hooks are deterministic. "If you keep adding emphasis to a CLAUDE.md line and Claude still misses it, that's a sign the line belongs in a hook."
- **Claude Code skills docs** (https://code.claude.com/docs/en/skills): a skill body is injected once and never re-read. After compaction only the first 5k tokens of each skill come back, within a 25k budget. The skill listing gets about 1% of context; rarely used descriptions drop first.

Not found anywhere: a measurement of skill-to-skill handoffs, or of review-loop termination.

## Approaches considered

### Deterministic controls in the harness

All three major coding harnesses have hooks that can block or force the agent to continue (checked against their docs, October 2026):

- **Claude Code** (https://code.claude.com/docs/en/hooks): `UserPromptSubmit` can inject context; `PreToolUse` on `Agent` can deny a spawn; `Stop` can refuse to finish (capped at 8 consecutive blocks, reset by tool calls). Hooks in a skill's frontmatter apply once it loads. A subagent's `skills:` field preloads full skill text. Workflow scripts (https://code.claude.com/docs/en/workflows) put control flow in JavaScript (`agent()` with a schema, `parallel()`, `pipeline()`), with no mid-run user input.
- **Codex** (https://learn.chatgpt.com/docs/hooks): a near copy of Claude Code's events and Stop `block`; no documented block cap.
- **Cursor** (https://cursor.com/docs/agent/hooks): can deny a subagent start and auto-send a follow-up on stop (`loop_limit` 5); no context injection on prompt submit.
- No shared hooks standard. Skills and `AGENTS.md` are the only portable layers, and both are advisory.

Mapped to the failures: a prompt-router hook for (1), `PreToolUse` on `Agent` for (2), merging skills or preloading for (3), a Workflow script or a CI review bot for (4), a single owner or an output schema for (5).

**Set aside for now.** This repo ships skills through `npx skills` into several harnesses. Hooks and workflow scripts live in each harness's own settings, differ between harnesses, and may not run at all when a GUI or wrapper sits in front of the CLI. They stay an option for single, rule-must-hold cases.

### Process as code elsewhere

- Anthropic, "Building effective agents" (2024-12) and "Harness design for long-running application development" (2026-03): a separate evaluator with hard pass/fail thresholds. Their solo run took 20 min and $9 and broke the core feature; the full harness took 6 h and $200 and worked (n=1).
- OpenAI, "Harness engineering" (2026-02, read through secondary write-ups): rules as custom lints and structural tests with fix instructions in the messages; a ~100-line `AGENTS.md` as a map.
- Martin Fowler site, Birgitta Böckeler (2026-04): guides before the agent acts, sensors after; computational sensors first.
- Ralph loop, superpowers (a `SessionStart` hook injecting its gateway skill), Spec Kit, Kiro, BMAD, Amp checks. Effectiveness claims are mostly anecdotal.

Recurring patterns: guidance in prose and invariants in code; state in files that each step re-reads; a separate verifier with explicit bounds; scaffolding treated as provisional.

### pstack

Lauren Tan's pstack (MIT, https://github.com/cursor/plugins/tree/main/pstack) is the closest prior art. `/poteto-mode` is a user-only front door that matches the task to one of 23 playbooks, 10–30 lines each. Almost every other pstack skill is user-only too, read by file path, so none of them has to fire on its own. Taken from it:

- Playbook steps copied word for word into the todo list, with `skip: <reason>` kept visible.
- Sticky mode, with "new task" to re-match.
- A `Reply:` line per playbook, so each report has one owner.
- A one-line role at the top of each playbook ("You own the answer").
- Explicit handoffs between playbooks (investigation and prototype hand off to feature).

Left out: the scale, the author's personal style rules, mandatory delegation of all code, and team or enterprise playbooks. Nothing in pstack enforces its steps, and no compliance numbers have been published for it.

## What we built: the `do` gateway

`/do <task>` (or `/do <playbook> <task>`) picks a playbook, copies its steps into the task list, and stays on for the session. Playbooks own step order, review rounds and the report; skills keep the judgment. It starts with build, design and general.

**Choosing the playbooks.** Sort real first prompts from past sessions into groups, and give the big groups a playbook. In our sample:

- UI and design work (redesign, polish, prototype) was the largest group, bigger than feature work.
- About a third of sessions wanted an answer, not code: an opinion, a status check, outside research.
- Sessions often turn from a proposal into a build, so playbooks hand off to each other by name.

**Habit is the main risk.** A gateway only works if it gets typed. Installing one is not the same as using it as the front door, so check usage after a few weeks.

**Cold runs.** Expected results were written before each run.

- Playbook pick: two fresh agents classified 14 real-style requests and agreed on all 14. A request to edit a skill went to general in both, not build.
- Build, run 1: all steps done, but with no task-list tool the checklist only appeared in the final reply, and skipped steps lost their text.
- Build, run 2, after rewording the fallback to "send the checklist before step 1": ignored again. The review loop worked: round 1 (cross-provider) found a weak test, the fix went in, round 2 was clean, round 3 was skipped.
- Build, run 3, after changing the fallback to writing `.evidence/<task>/steps.md`: written before any code change, steps word for word, skips kept their text.

Lesson: an instruction to *say* something mid-task was skipped twice. An instruction to *write a file* held. Where the session has no task-list tool, the file is the mechanism.

## Open

- Playbooks still to write: advise, debug, skill.
- The design playbook has not had an end-to-end run.
- Making the called skills user-only and reading them by path, as pstack does.
- Checking whether `/do` actually gets typed, a few weeks in.
