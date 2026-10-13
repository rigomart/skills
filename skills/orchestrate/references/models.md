# Models

The models subagents may run on, per tier. Only Claude models for now: every subagent runs on one of these, whatever other models a tool, a CLI on the machine (`codex exec`, `gemini`), or another skill's configuration offers.

Use the family name; versions change over time and the spawn tool lists what is current.

| Tier | Family |
| --- | --- |
| Light | Haiku |
| Standard | Sonnet |
| Deep | Opus |

Fable, the frontier family, is not a subagent tier. Use it for a subagent only when the user asks for it on that workstream.

## Setting it in Claude Code

- The `Agent` tool's `model` field takes the family alias: `haiku`, `sonnet`, `opus`. Check its enum before the first spawn.
- Set its `effort` field to `high` on every spawn.
- Agent types that pick their own model have `model:` in their definition: `.claude/agents/*.md`, `~/.claude/agents/*.md`, or a plugin's agents. Leave `model` unset for those.
- Unset otherwise means the configured default subagent model, or your session's model when there is none.

## Session cap

A Sonnet session runs Deep work on Sonnet, and the plan says so. A Haiku session runs everything on Haiku.
