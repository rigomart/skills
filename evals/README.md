# Evals

Runs a skill's scenarios headless on a chosen model and reports how often each check passes. Use it to prove a skill on the cheapest model expected to run it.

```bash
evals/run.sh ship-changes                                   # its floor, 3 runs per scenario
evals/run.sh ship-changes --model claude-opus-5-5 --effort high
evals/run.sh ship-changes --only stack-migration --runs 5
```

Results land in `evals/results/<skill>/<timestamp>-<model>-<effort>/` (gitignored): `summary.md`, and per run the transcript, the fake `gh` state and calls, the git graph and `checks.txt`. Each run's working directory stays in `$TMPDIR`; its path is in `workdir`. The summary's heading names the model and effort, and says `(floor)` when they are the skill's floor.

## Model floors

Each skill is proven on its floor, the weakest model expected to run it:

| Skill kind | Floor |
| --- | --- |
| Procedural (follow steps, fill templates, run scripts) | Haiku 5.5, effort `xhigh` |
| Judgment (shape, decide, review) | Sonnet 5.5, effort `high` |

`evals/<skill>/floor` holds it as one line, the model ID and the effort:

```text
claude-haiku-5-5 xhigh
```

`run.sh` uses the floor unless `--model` or `--effort` replaces its half. A skill with no floor file needs both flags.

## How a run is isolated

- The fixture repo and a bare `origin` are built fresh in a temp dir by the scenario's `setup.sh`.
- The skill, and the scenario's extra skills, are copied in as project skills, and `claude` runs with `--setting-sources project`, so your user skills, plugins, hooks and `CLAUDE.md` don't load.
- `--strict-mcp-config` with no `--mcp-config` loads no MCP servers, so your claude.ai connectors and other MCP servers stay out. `--setting-sources project` alone still loads the connectors.
- The scheduling tools are hidden: `ScheduleWakeup`, `CronCreate`, `CronDelete`, `CronList` and `RemoteTrigger`. A headless run can't be woken later, and `ScheduleWakeup`'s description invites a background heartbeat that small models sometimes act on. `RemoteTrigger` would also create routines on your account. `Monitor` stays, because it works in a headless run and the `babysit-pr` checks count it.
- The task-list tools (`TaskCreate`, `TaskUpdate`) are on, as in an interactive session; `claude -p` hides them by default.
- `gh` on `PATH` is [lib/fake-gh](lib/fake-gh): it answers from `state.json`, refuses `pr create` for an unpushed branch, and logs every call to `calls.jsonl`. Real `gh` gets an empty config dir and no token.
- Permissions are bypassed inside the temp dir. Pushes go to the local bare repo.

## Add a scenario

A folder under `evals/<skill>/` with:

- `setup.sh`: sourced with `REPO`, `REMOTE` and `EVAL_GH_STATE` set and [lib/fixture.sh](lib/fixture.sh) loaded. Build the repo state the agent starts from.
- `prompt.txt`: what the user types.
- `check.sh`: sourced after the run with [lib/checks.sh](lib/checks.sh) loaded. Print one `PASS <name>` or `FAIL <name>: <detail>` line per check.
- `skills` (optional): other skills from `skills/` to install next to the one under test, one name per line. Use it when the skill loads others, such as `ship-changes` loading `comments` and `unslop`. `run.sh` stops before any run if a name has no folder.

Each skill with scenarios also has a `floor` file, described under [Model floors](#model-floors).

Before trusting a new check, make it pass on a hand-made ideal run, and run Opus once as a baseline. A check Opus fails is usually unclear skill text or a wrong check, not a small-model problem. To try `check.sh` on a hand-made transcript without a run, source the helpers yourself: `TRANSCRIPT=ideal.jsonl EVAL_SKILL=<skill> bash -c 'source evals/lib/checks.sh; check_skill_loaded'`.

## Transcript helpers

[lib/checks.sh](lib/checks.sh) reads the run's `stream-json` transcript. Each helper prints one line per item, except `skill_loaded`, which only sets its exit status:

| Helper | Prints |
| --- | --- |
| `tool_uses`, `main_tool_uses` | Each tool call as JSON. `tool_uses` includes the calls subagents made; `main_tool_uses` leaves them out. |
| `bash_cmds`, `final_text` | Each Bash command; the final reply. |
| `skill_loaded [skill]`, `check_skill_loaded [skill]` | Whether the skill was invoked or its `SKILL.md` read; the skill under test when none is named. The check is `skill_loaded`, or `<skill>_loaded` for another skill. |
| `subagent_spawns` | Each subagent spawn, nested ones too: `{id, parent, type, model, description, prompt, background}`. `model` is null when the spawn named none; `background` is what the spawn asked for. |
| `subagent_models` | Each spawn's `model`, or `unset`. |
| `subagent_tool_uses <id>` | The tool calls of the subagent that spawn `<id>` started. |
| `task_calls` | Each `TaskCreate` and `TaskUpdate` call by the main agent: `{tool, task, subject, description, status, error}`, with null for what the call left out and `error` true when it failed. |
| `task_list` | The main agent's task list as it ended, from the calls that succeeded: `<id><TAB><status><TAB><subject>` per task in creation order. |

Two checks built on them, that every spawn named a model and that the third task ended completed:

```bash
if subagent_models | grep -qx unset; then fail spawns_set_model "a spawn named no model"; else pass spawns_set_model; fi
expect third_task_done "task 3 ended $(task_list | sed -n 3p | cut -f2)" test "$(task_list | sed -n 3p | cut -f2)" = completed
```
