# Models

The models subagents may run on, per tier and vendor. Do not route work to any other model, whatever a tool, a CLI on the machine, or another skill's configuration offers.

| Tier | Claude | OpenAI |
| --- | --- | --- |
| Deep (default) | Opus | Sol |
| Standard | Sonnet | Sol |
| Light | Haiku | Luna |

The frontier families (Claude Fable, OpenAI Astra) are not a subagent tier. Use one for a subagent only when the user asks for it on that workstream.

## Newest version only

A family means its newest version. Read the versions from the live model list when you spawn, and pick the highest one in the family. Never pick an older version that is still listed, the tool's default, or the first entry. If a family has no model in the list at all, that tier is missing.

## Default pairing

Claude implements; OpenAI reviews. When the work under review ran on OpenAI, Claude reviews it.

## Reasoning effort

Set reasoning effort to `high` on every spawn, for every family. Never use a higher level.

## Setting it in Claude Code

- The `Agent` tool's `model` field takes the family alias: `opus`, `sonnet`, `haiku`. Check its enum before the first spawn.
- Set its `effort` field to `high`.
- Agent types that pick their own model have `model:` in their definition: `.claude/agents/*.md`, `~/.claude/agents/*.md`, or a plugin's agents. Leave `model` unset for those.
- Unset otherwise means the configured default subagent model, or your session's model when there is none.

## Setting it in Codex

- Codex takes a full model id, not a family alias. Pick the newest id in the tier's family from the models the spawn tool accepts. Never build an id by hand.
- Leave the model unset for a custom agent whose definition sets its own.

## Session cap

A Fable, Astra, Opus, or Sol session follows the tiers as written. A Sonnet session runs Deep work on Sonnet and keeps Light on Haiku, and the plan says so. A Haiku or Luna session runs everything on its own model.
