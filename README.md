# ralph

Autonomous software evolution loop. Based on the Ralph pattern by [Geoffrey Huntley](https://ghuntley.com/ralph/).

Bash controls the loop. Claude writes and verifies the code. Tests are the judge. No human checkpoints.

---

## How it works

```
┌─────────────────────────────────────────────────┐
│                    loop.sh                       │
│                                                  │
│   while specs/ is not empty:                     │
│     spawn claude (fresh context)                 │
│       ↓                                          │
│     claude reads: CLAUDE.md + PRD.md             │
│     claude picks: lowest-numbered spec           │
│     claude writes: code                          │
│     claude runs:  tests / lint / typecheck       │
│     claude fixes: until all criteria pass        │
│     claude moves: spec → specs/done/             │
│     claude writes: progress.txt                  │
│       ↓                                          │
│     bash commits all changes to git              │
│     bash waits PAUSE_SECONDS                     │
│     bash spawns next claude process              │
└─────────────────────────────────────────────────┘
```

Every Claude session starts with a clean context window. It reads `progress.txt` to know what happened last. It reads `specs/` to know what to do next. Git history is the long-term memory.

There is no inbox, no outbox, no human approval queue. The tests pass or they don't.

---

## Quickstart

### Option A — Run directly (simpler, less isolated)

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed.

```bash
# 1. Configure your project
cp PRD.example.md PRD.md
# Edit PRD.md — describe the project, test commands, conventions

# 2. Add your first spec
cp specs/000-spec-template.md.example specs/001-first-feature.md
# Edit it

# 3. Run in a tmux session
chmod +x loop.sh
tmux new-session -s ralph
./loop.sh
# Detach: Ctrl+B D    Reattach: tmux attach -t ralph
```

### Option B — Run in Docker (recommended)

Claude gets access only to the project directory. Nothing else on your machine is reachable.

Requires [Docker](https://docs.docker.com/get-docker/) installed.

```bash
# 1. Configure your project (same as above)
cp PRD.example.md PRD.md

# 2. Set your API key
export ANTHROPIC_API_KEY=sk-ant-...

# 3. Run
chmod +x docker-run.sh
./docker-run.sh
```

The container mounts your project directory read-write, so all changes (code and git commits) appear on your local filesystem in real time.

By default the container runs with `--network none`. If your project needs to fetch dependencies during the loop, remove that line from `docker-run.sh`.

---

## Adding specs

Each file in `specs/` is one unit of work. Files are processed in filename order — use numeric prefixes to control priority.

```bash
# Copy the template
cp specs/000-spec-template.md.example specs/005-add-pagination.md
# Fill it out, then let the loop pick it up on the next iteration
```

**Keep specs small.** One focused feature or behavior per spec. If a spec takes more than one iteration to complete (it shouldn't), split it.

The agent will not mark a spec done until its acceptance criteria pass. Write acceptance criteria that are machine-checkable — "pnpm test passes" not "the feature works."

---

## Monitoring

```bash
# What's happening right now
tail -f logs/loop-*.log | tail -1

# What happened in the last iteration
cat progress.txt

# Full history
git log --oneline

# What changed in the last iteration
git diff HEAD~1

# All specs remaining
ls specs/

# All completed specs
ls specs/done/
```

---

## Emergency controls

```bash
# Stop immediately
Ctrl+C

# Undo the last iteration
git reset --hard HEAD~1

# Undo last N iterations
git reset --hard HEAD~N

# Run one iteration and stop (useful for testing your PRD)
./loop.sh --once

# Preview the prompt without running
./loop.sh --dry-run
```

---

## Tuning

### Iteration speed

```bash
# Fast (good for greenfield, low stakes)
PAUSE_SECONDS=5 ./loop.sh

# Slow (good for reviewing between iterations)
PAUSE_SECONDS=120 ./loop.sh
```

### Cap total iterations

```bash
MAX_ITERATIONS=20 ./loop.sh
```

### When the loop does something wrong

That's a tuning signal. Don't blame the tool — add a rule to `PRD.md` so it never happens again. The PRD gets sharper over time as you tune it.

Common additions:
- A specific pattern it keeps getting wrong → add to **Coding conventions**
- A file it shouldn't be touching → add to **Constraints and guardrails**  
- A test command it's running incorrectly → fix **How to run tests**

---

## NEEDS_HUMAN

If the loop hits something it genuinely can't resolve, it writes `STATUS: NEEDS_HUMAN` to `progress.txt` and stops. Read the `REASON:` and `ATTEMPTS:` fields to understand what happened.

To resume after resolving the blocker:
1. Fix whatever caused the block
2. Edit `progress.txt` — change `STATUS: NEEDS_HUMAN` to `STATUS: MORE_WORK`
3. Restart the loop

---

## Security

`loop.sh` uses `--dangerously-skip-permissions`. This is required for autonomous operation — permission prompts would break the loop. It means Claude can read and write anything inside the working directory.

**This is why Docker is recommended.** The container hard-limits what Claude can touch to your project directory via the volume mount. Your SSH keys, credentials, other projects, and the rest of your filesystem are not reachable from inside the container.

Note: outbound network access is required. Claude Code must reach `api.anthropic.com` to function. The container does not expose any inbound ports.

Regardless of Docker or not:
- Never put production credentials in the project directory while the loop is running
- Never run this on a machine where the blast radius of a runaway agent matters
- Use environment variables for secrets, and confirm your `.env` file is in `.gitignore`

---

## Project layout

```
/
├── loop.sh                          ← bash controller (never edit)
├── CLAUDE.md                        ← agent engine rules (rarely edit)
├── PRD.md                           ← YOUR project config (fill this out)
├── PRD.example.md                   ← template to copy from
├── Dockerfile                       ← sandbox image
├── docker-run.sh                    ← convenience wrapper for Docker
├── progress.txt                     ← state handoff between iterations
├── .gitignore
├── specs/
│   ├── 000-spec-template.md.example ← copy this to write new specs
│   ├── 001-your-first-spec.md       ← add your specs here
│   └── done/                        ← completed specs land here
├── logs/                            ← timestamped loop logs (gitignored)
└── [your project code]              ← the codebase being evolved
```

---

## Credits

Ralph pattern by [Geoffrey Huntley](https://ghuntley.com/ralph/).  
"Everything is a ralph loop" — [ghuntley.com/loop](https://ghuntley.com/loop/).
