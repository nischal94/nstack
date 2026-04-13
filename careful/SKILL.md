---
name: careful
description: Use when working in an environment where destructive commands should require confirmation before running. Use when the user says "be careful", "careful mode", "don't delete anything without asking", or when working on production data, shared infrastructure, or irreversible operations. Use `/careful here` or `/careful <path>` for full safety mode — warnings + directory-scoped edits combined — before high-stakes work on production code where both scope and safety matter.
---

# /careful — Destructive Command Guardrails

Two modes:

- **`/careful`** (default) — warns before destructive or hard-to-reverse commands
- **`/careful <path>`** or **`/careful here`** — warnings AND directory-scoped edits combined. "here" is sugar for the current working directory. Use this for high-stakes sessions where both scope and safety matter (production code, shared infrastructure, full lockdown).

You are operating in careful mode. Before running any destructive or hard-to-reverse
command, you pause, describe what it will do, and get explicit confirmation.

**This skill changes your behavior for the rest of the session.**
It does not affect read-only operations — only commands that destroy, overwrite, or
publish data in ways that are difficult or impossible to undo.

In scoped mode (`/careful <path>` or `/careful here`), it ALSO blocks any write
outside the specified directory — combining the destructive-warning layer with
the scope-lock layer for maximum safety.

---

## Arguments

- `/careful` — warnings only, no directory lock
- `/careful src/api/` — warnings + lock edits to `src/api/` and subdirectories
- `/careful src/api/auth.ts` — warnings + lock edits to a single file
- `/careful here` — warnings + lock edits to the current working directory (sugar for `/careful .`)
- `/freeze lift` — remove the directory lock portion, leaves warnings active
- "exit careful mode" — remove both warnings and scope lock

---

## What triggers a confirmation pause

### Filesystem destruction
- `rm -rf`, `rm -r`, `rm -f` on anything outside `/tmp`
- `git clean -f`, `git clean -fd`
- Overwriting files without a backup: `> file` (truncate), `mv` that overwrites
- Deleting database files, migration files, seed data

### Git — hard to reverse
- `git reset --hard`
- `git push --force`, `git push --force-with-lease`
- `git checkout --` (discard working tree changes)
- `git branch -D` (delete branch, especially if unmerged)
- `git rebase` on a shared branch

### Database
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`
- `DELETE FROM` without a `WHERE` clause
- Running migrations on a production database
- Any destructive SQL on non-localhost connection strings

### Infrastructure
- `kubectl delete`
- `terraform destroy`
- Scaling to zero on a live service
- Deleting cloud resources (S3 buckets, RDS instances, etc.)

### Publishing / external state
- Sending emails or notifications to real users
- Posting to external APIs (Slack, webhooks, payment processors) in non-test mode
- Publishing npm packages, PyPI releases, Docker images
- Merging to main/master (if not part of an explicit `/ship` flow)

---

## The confirmation format

Before running any of the above, output:

```
⚠️  CAREFUL MODE — Destructive operation detected

Command:   [exact command about to run]
Effect:    [what it will do in plain English]
Reversible: [Yes — how / No — why not]

Confirm? (yes / no / show me what would be affected first)
```

Wait for explicit "yes" before proceeding. "ok", "sure", "go ahead" count as yes.
"show me first" means run a dry-run or preview command first.

If the user says **no**: stop, explain what safe alternatives exist.

---

## What does NOT trigger a pause

- Read operations (cat, ls, grep, git log, git diff, git status)
- Write operations to `/tmp` or clearly temporary paths
- Creating new files (not overwriting)
- Running tests
- Installing dependencies (npm install, pip install)
- Building the project
- Linting

---

## Scoped mode (`/careful <path>` and `/careful here`)

When invoked with a path argument (or `here` for the current working directory), activate both layers:

### Activation banner

```
CAREFUL MODE — SCOPED
═════════════════════
Warnings:   ON  — destructive commands require confirmation
Scope lock: ON  — edits locked to [path]
Reads:      unrestricted

This session is now operating under maximum safety constraints.
To exit: say "exit careful mode" (removes both), or `/freeze lift` (keeps warnings).
```

### Behavior

**Destructive commands:** apply the confirmation pause above (same as default mode).

**File writes:** apply the `/freeze` enforcement rules — any Edit, Write, or file-creation operation outside the locked path is blocked. See `/freeze` for the full enforcement spec.

### Combined precedence

If a command is both destructive AND writes outside the scoped path:
- Block the write first (scope violation — the edit can't happen)
- Do not proceed to the destructive confirmation — the command is already blocked

### Session reminder

At the start of each new task in scoped mode:

```
[careful mode: warnings ON + edits locked to [path]]
```

### When to use scoped vs default

| Situation | Invocation |
|-----------|------------|
| "Warn me before destructive commands, but let me write anywhere" | `/careful` |
| "Only touch `src/auth/`, destructive warnings optional" | `/freeze src/auth/` |
| "High-stakes session — lock scope AND warn me on everything dangerous" | `/careful src/auth/` |
| "Touching prod infrastructure, full lockdown" | `/careful here` or `/careful .` |

---

## Staying in careful mode

Careful mode persists for the entire session once activated. The scope lock (if active) also persists until explicitly cleared.

To exit:
- "exit careful mode" — removes both warnings and any scope lock
- `/freeze lift` — removes the scope lock only, leaves warnings active

Remind the user at the start of each new task:
```
[careful mode active — destructive commands require confirmation]
```

Or in scoped mode:
```
[careful mode: warnings ON + edits locked to [path]]
```

---

## Rules

- **Pause first, ask second.** Never run a destructive command speculatively.
- **Be specific about irreversibility.** "This will permanently delete 47 files" is more useful than "this deletes files."
- **Offer the dry-run.** Most destructive commands have a preview: `rm -n`, `git push --dry-run`, `terraform plan`. Offer it.
- **Don't be paranoid.** This is not about slowing down routine work — it's about catching the one command that costs hours to recover from.
- **In scoped mode, enforce both layers.** All rules from default mode apply in full, plus `/freeze` enforcement. When both trigger on the same command, scope block takes precedence.
- **`/freeze lift` removes the scope lock but leaves warnings active.** "exit careful mode" removes both.
