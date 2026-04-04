---
name: checkpoint
description: Use when saving working state at the end of a session, or resuming at the start of a new one. Triggers on "checkpoint", "save progress", "where was I", "resume", "pick up where I left off", or before running /compact or /handoff.
---

# /checkpoint — Save & Resume Working State

Git checkpoint for founders building at speed. Works in two modes:

- **Save mode** — commit current state with structured context for future recovery
- **Resume mode** — read the last checkpoint and surface exactly where you left off

---

## Mode Detection

Check which mode to run:

1. Run `git status --short` to see if there are uncommitted changes
2. Run `git log --oneline -1` to see the last commit message

**If there are uncommitted changes** → run Save mode  
**If working tree is clean** → run Resume mode  
**If user explicitly says "resume" or "where was I"** → always run Resume mode

---

## Save Mode

### Step 1 — Verify git repo
```bash
git rev-parse --git-dir 2>/dev/null
```
If not a git repo: tell the user "Not a git repository. /checkpoint only works in git projects." and stop.

### Step 2 — Check for changes
```bash
git status --short
```
If nothing to commit: tell the user "Nothing to commit. Run /checkpoint at the end of a session with uncommitted changes." and stop.

### Step 3 — Ask two questions
Ask the user:
- **What did you build or change?** (one sentence — the "what")
- **What's the next step?** (one sentence — where to pick up next session)

### Step 4 — Infer context
From the conversation, infer **why this matters** — the problem being solved, the decision made, or the constraint discovered. Do not ask the user for this — derive it yourself.

### Step 5 — Stage and commit
```bash
git add -A
```

Commit with this format:
```
<type>: <what they built/changed>

Context: <why this matters — inferred from conversation>
Next: <what they said comes next>
```

Use the right prefix:
- `feat:` — new feature or capability
- `fix:` — bug fix
- `refactor:` — restructuring without behavior change
- `docs:` — documentation only
- `chore:` — config, deps, tooling

### Step 6 — Confirm
Show the commit hash and the full commit message so the user can verify it captured the right context.

---

## Resume Mode

### Step 1 — Read last checkpoint
```bash
git log --oneline -5
git show HEAD --stat --format="%s%n%n%b"
```

### Step 2 — Surface the state
Output a structured resume summary:

```
CHECKPOINT RESUME
═════════════════
Last saved:  <relative time, e.g. "2 hours ago">
Branch:      <current branch>
Commit:      <hash> — <subject>

What was done:
  <commit subject — the "what">

Why it matters:
  <Context: line from commit body>

Pick up here:
→ <Next: line from commit body>

Files changed in last checkpoint:
  <list from git show --stat>
```

### Step 3 — Check for uncommitted work
```bash
git status --short
```
If there are uncommitted changes left over, warn:
> "There are uncommitted changes from the last session. Run /checkpoint save to capture them, or review with `git diff`."

---

## Rules

- **Never use `--no-verify`** — always run hooks
- **Stage with `git add -A`** — capture everything including new files
- **Infer context from conversation** — don't ask the user to explain what Claude already knows
- **Resume is read-only** — never commit in Resume mode
- **One checkpoint per logical unit of work** — don't checkpoint every small change, checkpoint when switching context or ending a session
