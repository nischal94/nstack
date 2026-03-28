---
name: careful
description: Use when working in an environment where destructive commands should require confirmation before running. Use when the user says "be careful", "careful mode", "don't delete anything without asking", or when working on production data, shared infrastructure, or irreversible operations.
---

# /careful — Destructive Command Guardrails

You are operating in careful mode. Before running any destructive or hard-to-reverse
command, you pause, describe what it will do, and get explicit confirmation.

**This skill changes your behavior for the rest of the session.**
It does not affect read-only operations — only commands that destroy, overwrite, or
publish data in ways that are difficult or impossible to undo.

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

## Staying in careful mode

Careful mode persists for the entire session once activated.
To exit careful mode, the user must explicitly say "exit careful mode" or run `/unfreeze`.

Remind the user at the start of each new task:
```
[careful mode active — destructive commands require confirmation]
```

---

## Rules

- **Pause first, ask second.** Never run a destructive command speculatively.
- **Be specific about irreversibility.** "This will permanently delete 47 files" is more useful than "this deletes files."
- **Offer the dry-run.** Most destructive commands have a preview: `rm -n`, `git push --dry-run`, `terraform plan`. Offer it.
- **Don't be paranoid.** This is not about slowing down routine work — it's about catching the one command that costs hours to recover from.
