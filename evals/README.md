# Evals

Runs a skill's scenarios headless on a chosen model and reports how often each check passes. Use it to prove a skill on the cheapest model expected to run it.

```bash
evals/run.sh ship-changes                                   # Haiku 5.5, xhigh, 3 runs per scenario
evals/run.sh ship-changes --model claude-sonnet-5-5 --effort high
evals/run.sh ship-changes --only land-armed --runs 5
```

Results land in `evals/results/<skill>/<timestamp>-<model>-<effort>/` (gitignored): `summary.md`, and per run the transcript, the fake `gh` state and calls, the git graph and `checks.txt`. Each run's working directory stays in `$TMPDIR`; its path is in `workdir`.

## Model floors

Each skill is proven on the weakest model expected to run it:

| Skill kind | Floor |
| --- | --- |
| Procedural (follow steps, fill templates, run scripts) | Haiku 5.5, effort `xhigh` |
| Judgment (shape, decide, review) | Sonnet 5.5, effort `high` |

## How a run is isolated

- The fixture repo and a bare `origin` are built fresh in a temp dir by the scenario's `setup.sh`.
- The skill is copied in as a project skill, and `claude` runs with `--setting-sources project`, so your user skills, plugins, hooks and `CLAUDE.md` don't load.
- `gh` on `PATH` is [lib/fake-gh](lib/fake-gh): it answers from `state.json`, refuses `pr create` for an unpushed branch, and logs every call to `calls.jsonl`. Real `gh` gets an empty config dir and no token.
- Permissions are bypassed inside the temp dir. Pushes go to the local bare repo.

## Add a scenario

A folder under `evals/<skill>/` with:

- `setup.sh`: sourced with `REPO`, `REMOTE` and `EVAL_GH_STATE` set and [lib/fixture.sh](lib/fixture.sh) loaded. Build the repo state the agent starts from.
- `prompt.txt`: what the user types.
- `check.sh`: sourced after the run with [lib/checks.sh](lib/checks.sh) loaded. Print one `PASS <name>` or `FAIL <name>: <detail>` line per check.

Before trusting a new check, make it pass on a hand-made ideal run, and run Opus once as a baseline. A check Opus fails is usually unclear skill text or a wrong check, not a small-model problem.
