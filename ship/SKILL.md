---
name: ship
description: Use when implementation is complete and you want to run tests, review, bump version, update changelog, and open a PR in one command. Use when the user says "ship it", "ship this", "push this", "open a PR", "release this", or "let's ship".
---

# /ship — Ship It

You are a release engineer. You run the full shipping checklist: tests, code review,
version bump, CHANGELOG, commit, push, PR. One command. No half-measures.

**Prerequisite:** Implementation must be complete and tests must exist.
If neither is true, use `superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development` first.

## Arguments

- `/ship` — ship current branch with full checklist
- `/ship --draft` — open a draft PR (don't mark ready for review)
- `/ship --skip-review` — skip code review step (use for small fixes only)
- `/ship --no-bump` — don't bump version (use when not a versioned release)

---

## Step 1: Pre-flight checks

```bash
# Confirm we're on a feature branch, not main/master
git branch --show-current

# Check for uncommitted changes
git status --short

# Confirm upstream / remote
git remote -v
git log --oneline origin/main..HEAD 2>/dev/null || git log --oneline origin/master..HEAD 2>/dev/null
```

If on `main`/`master`: stop and ask the user to confirm. Shipping directly to main is unusual.
If there are uncommitted changes: ask the user whether to commit them first or stash.

---

## Step 2: Run the test suite

Run whichever test runner the project uses:

```bash
# Detect and run tests
npm test 2>/dev/null || \
python -m pytest 2>/dev/null || \
go test ./... 2>/dev/null || \
cargo test 2>/dev/null || \
bundle exec rspec 2>/dev/null
```

If tests fail: **stop**. Do not proceed. Report which tests failed.
Use `superpowers:systematic-debugging` to fix, then re-run `/ship`.

If no tests found: warn the user and ask whether to continue anyway.

---

## Step 3: Self-review the diff

```bash
# What are we actually shipping?
git diff main..HEAD --stat 2>/dev/null || git diff master..HEAD --stat 2>/dev/null
git log --oneline main..HEAD 2>/dev/null || git log --oneline master..HEAD 2>/dev/null
```

Read the diff. Check for:
- Debug statements left behind (`console.log`, `print(`, `debugger`, `TODO:`)
- Hardcoded secrets or API keys
- Commented-out code that shouldn't ship
- Test files accidentally included in production paths

If any found: list them and ask the user whether to fix before shipping.

---

## Step 4: Code review (unless --skip-review)

Dispatch `superpowers:requesting-code-review` with the current diff as context.

This is a lightweight pass — focus on:
- Correctness: Does the logic do what was intended?
- Security: Any obvious vulnerabilities introduced?
- Breaking changes: Anything that could break callers?

If the review surfaces CRITICAL issues: stop and fix before proceeding.
If MINOR issues only: list them, ask whether to fix now or file as follow-up.

---

## Step 5: Version bump (unless --no-bump)

Detect versioning scheme:

```bash
# Node
cat package.json 2>/dev/null | grep '"version"'

# Python
cat pyproject.toml setup.py 2>/dev/null | grep "version"

# Go — check git tags
git describe --tags --abbrev=0 2>/dev/null

# Rust
cat Cargo.toml 2>/dev/null | grep "^version"
```

Determine the bump type from the commits since last tag:
- Any `BREAKING CHANGE` or `feat!:` → **MAJOR**
- Any `feat:` → **MINOR**
- Only `fix:`, `docs:`, `chore:` → **PATCH**

Show the proposed version and ask for confirmation:

```
Current version: 0.3.2
Proposed bump:   MINOR (new features in this branch)
New version:     0.4.0

Confirm? (y/n/custom)
```

Wait for confirmation before writing anything.

---

## Step 6: Update CHANGELOG.md

Run `/document-release --draft` logic inline:
- Group commits by type
- Consolidate related commits into single entries
- Write the new entry to the top of CHANGELOG.md

If no CHANGELOG.md exists, create one.

---

## Step 7: Commit the release artifacts

```bash
git add CHANGELOG.md
# Add version file if it was bumped
# package.json / pyproject.toml / Cargo.toml as appropriate
git commit -m "chore: bump version to vX.Y.Z and update CHANGELOG"
```

---

## Step 8: Push and open PR

```bash
git push origin $(git branch --show-current)
```

Then use the GitHub MCP to create a PR:
- **Title:** derived from the branch name or primary commit
- **Body:** the CHANGELOG entry for this version
- **Draft:** if `--draft` flag was passed
- **Base branch:** main or master (auto-detected)

Output:

```
SHIPPED
═══════
Branch:   feat/your-feature
Version:  v0.4.0
Tests:    ✓ passed
Review:   ✓ clean
PR:       https://github.com/owner/repo/pull/123
```

---

## Rules

- **Tests must pass.** No exceptions. Don't skip, don't suppress.
- **Never ship directly to main without confirmation.** Even if asked.
- **One PR per ship.** Don't batch unrelated branches.
- **If anything in the checklist fails, stop and report.** Don't silently skip steps.
- **Version bumps need user confirmation.** You propose, user decides.
- **Hand off, don't reimplement.** Use `superpowers:requesting-code-review` for review — don't write your own review logic.
