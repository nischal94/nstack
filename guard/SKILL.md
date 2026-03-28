---
name: guard
description: Use when you want both destructive command warnings AND directory-scoped edits in one command. Use when the user says "guard mode", "lock this and be careful", "guard this directory", or before high-stakes work on production code where both scope and safety matter.
---

# /guard — Full Safety Mode

Guard mode combines `/careful` and `/freeze` into a single activation.

- **`/careful`** — warns before destructive or hard-to-reverse commands
- **`/freeze [path]`** — locks all edits to a specific directory

Use `/guard` when you want both. Use the individual skills when you only need one.

## Arguments

- `/guard src/api/` — careful mode + freeze to `src/api/`
- `/guard .` — careful mode + freeze to current directory
- `/guard` (no path) — careful mode only, no directory lock (equivalent to `/careful`)
- `/unfreeze` — remove the directory lock (careful mode remains)
- exit careful mode — remove both

---

## On activation

```
GUARD MODE ACTIVE
═════════════════
Careful:    ON  — destructive commands require confirmation
Freeze:     ON  — edits locked to [path]
Reads:      unrestricted

This session is now operating under maximum safety constraints.
To exit: say "exit guard mode" or run /unfreeze (removes freeze, keeps careful).
```

---

## Behavior

Follows all rules from both constituent skills:

### From /careful
Before running any destructive command, output the confirmation prompt and wait.
See `/careful` for the full list of triggers.

### From /freeze
Block any Edit or Write outside the frozen path.
See `/freeze` for full enforcement rules.

### Combined — precedence
If a command is both destructive AND outside the frozen path:
- Block the edit first (freeze violation)
- Do not proceed to the careful confirmation — it's already blocked

---

## When to use /guard vs individual skills

| Situation | Skill |
|-----------|-------|
| "I trust you to write anywhere, just warn me before deleting things" | `/careful` |
| "Only touch `src/auth/`, I don't care about destructive warnings" | `/freeze src/auth/` |
| "High stakes session — lock scope AND warn me about everything dangerous" | `/guard src/auth/` |
| "We're touching prod infrastructure, full lockdown" | `/guard .` |

---

## Session reminder

At the start of each new task:

```
[guard mode: careful ON + edits locked to [path]]
```

---

## Rules

- All rules from `/careful` apply in full
- All rules from `/freeze` apply in full
- When both trigger on the same command, freeze takes precedence (block first)
- `/unfreeze` removes the directory lock but leaves careful mode active
- "exit guard mode" removes both
