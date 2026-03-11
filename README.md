# ralph

Autonomous software evolution loop. Based on the Ralph pattern by [Geoffrey Huntley](https://ghuntley.com/ralph/).

Bash controls the loop. Claude writes and verifies the code. Tests are the judge. No human checkpoints.

---

## How it works

```
┌─────────────────────────────────────────────────┐
│                  ralph-ralph-loop.sh                    │
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

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated (`claude auth login`)
- A Claude Max subscription (recommended) — the loop runs against your subscription, not API credits

---

## Quickstart

```bash
# 1. Configure your project
cp PRD.example.md PRD.md
# Edit PRD.md — describe the project, test commands, conventions

# 2. Add your first spec
cp specs/000-spec-template.md.example specs/001-first-feature.md
# Edit it

# 3. Run in a tmux session so it keeps going after you close the terminal
chmod +x ralph-loop.sh
tmux new-session -s ralph
./ralph-loop.sh
# Detach: Ctrl+B D    Reattach: tmux attach -t ralph
```

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

### Backlog

If the agent discovers work that's out of scope for the current spec, it writes new specs to `specs/backlog/`. These are not picked up automatically — review them and move the ones you want to `specs/` with a numeric prefix.

---

## Monitoring

```bash
# What's happening right now
tail -f logs/loop-*.log

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
./ralph-loop.sh --once

# Preview the prompt without running
./ralph-loop.sh --dry-run
```

---

## Tuning

### Iteration speed

```bash
# Fast (good for greenfield, low stakes)
PAUSE_SECONDS=5 ./ralph-loop.sh

# Slow (good for reviewing between iterations)
PAUSE_SECONDS=120 ./ralph-loop.sh
```

### Cap total iterations

```bash
MAX_ITERATIONS=20 ./ralph-loop.sh
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

`ralph-loop.sh` uses `--dangerously-skip-permissions`. This is required for autonomous operation — permission prompts would break the loop. It means Claude can read and write anything your user account can access.

- Never put production credentials in the project directory while the loop is running
- Never run this on a machine where the blast radius of a runaway agent matters
- Use environment variables for secrets, and confirm your `.env` file is in `.gitignore`
- Run in a dedicated tmux session so you can monitor and interrupt if needed

---

## Project layout

```
/
├── ralph-loop.sh                          ← bash controller (never edit)
├── CLAUDE.md                        ← agent engine rules (rarely edit)
├── PRD.md                           ← YOUR project config (fill this out)
├── PRD.example.md                   ← template to copy from
├── progress.txt                     ← state handoff between iterations
├── .gitignore
├── specs/
│   ├── 000-spec-template.md.example ← copy this to write new specs
│   ├── 001-your-first-spec.md       ← add your specs here
│   ├── backlog/                     ← agent-discovered work (review before promoting)
│   └── done/                        ← completed specs land here
└── logs/                            ← timestamped loop logs (gitignored)
```

---

## Credits

Ralph pattern by [Geoffrey Huntley](https://ghuntley.com/ralph/).
"Everything is a ralph loop" — [ghuntley.com/loop](https://ghuntley.com/loop/).
