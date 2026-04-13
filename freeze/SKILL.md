---
name: freeze
description: Use when you want to lock edits to a specific directory for the session — preventing Claude from touching any other files. Use when the user says "only touch X", "freeze to this directory", "don't edit anything outside Y", "scope this to Z", or before a focused refactor. Use `/freeze lift` when you want to remove an active lock and the user says "unfreeze", "remove the lock", "unlock edits", "lift the freeze", or "I want to edit other files now".
---

# /freeze — Directory Edit Lock

Two modes:

- **`/freeze <path>`** (default) — lock edits to a specific directory for the session
- **`/freeze lift`** — clear the active lock

When the `/freeze` command is invoked with a path argument, a subdirectory, or `.` — enter lock mode. When invoked with the word `lift` — enter unlock mode. The two modes share the same skill because they describe the same trust boundary from opposite sides.

---

## Mode 1: Lock

You are now locked to a specific directory. For the rest of this session, you may
**only** create or edit files within the frozen path. Reads are unrestricted.

**Why this exists:** When doing a focused refactor, security fix, or isolated feature,
it's easy to accidentally touch a file outside the intended scope. A freeze makes
that impossible — you can read anything to understand context, but write nowhere except
the locked directory.

### Arguments

- `/freeze src/api/` — lock edits to `src/api/` and all subdirectories
- `/freeze src/api/auth.ts` — lock edits to a single file
- `/freeze .` — lock to the current working directory
- `/freeze lift` — remove the active lock (see Mode 2 below)

---

## On activation

Confirm the freeze immediately:

```
FREEZE ACTIVE
═════════════
Locked to:  [path]
Reads:      unrestricted (you can read any file for context)
Writes:     only within [path]
Duration:   this session (until `/freeze lift`)

Any edit outside [path] will be blocked and reported.
```

---

## Enforcement rules

For every Edit, Write, or file-creation operation:

1. Resolve the target file path to absolute
2. Check: does it fall within the frozen path?
3. If YES → proceed normally
4. If NO → block and output:

```
🔒 FREEZE VIOLATION — Edit blocked

Attempted:  [file path]
Frozen to:  [frozen path]
Reason:     [file] is outside the frozen directory

To edit this file, first run `/freeze lift`.
```

Do NOT proceed with the edit. Do NOT ask "are you sure?" — just block it.

---

## What is NOT blocked

- Reading any file (Read, Grep, Glob) — unrestricted
- Bash commands that don't write files
- Git operations that are read-only (git log, git diff, git status)
- Running tests
- Installing dependencies

---

## What IS blocked

- Edit tool on any file outside the frozen path
- Write tool on any file outside the frozen path
- Bash commands that redirect output (`>`, `>>`) to files outside the frozen path
- Creating new files outside the frozen path

---

## Multiple freeze calls

If `/freeze` is called again while a freeze is active, update the frozen path:

```
FREEZE UPDATED
══════════════
Previous lock:  [old path]
New lock:       [new path]
```

---

## Session reminder

At the start of each new task within the session, remind the user:

```
[freeze active: edits locked to [path]]
```

---

---

## Mode 2: Lift

When invoked as `/freeze lift`, remove the active directory lock.

Confirm immediately:

```
FREEZE LIFTED
═════════════
Edits are now unrestricted.
Careful mode: [still active / not active]
```

If careful mode is still active, remind the user:

```
Note: /careful is still active — destructive commands still require confirmation.
Say "exit careful mode" to disable it.
```

If no freeze was active:

```
No freeze was active in this session.
```

### Lift rules

- Removes directory lock only — does not affect `/careful` mode (if active)
- Takes effect immediately for all subsequent edits
- No path argument needed — always clears the current lock

---

## Rules

- **Block silently and immediately.** No "are you sure?" — just report and stop.
- **Reads are never blocked.** Context gathering must always be possible.
- **One frozen path at a time.** Second `/freeze <path>` replaces the first.
- **Explicit `/freeze lift` to exit.** Don't auto-expire after a task completes.
- **Combined with `/careful`:** If both are active, both sets of rules apply. Lifting the freeze does not affect careful mode.
