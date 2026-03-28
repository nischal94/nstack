---
name: document-release
description: Use when preparing a release, tagging a version, writing a changelog, or summarizing what shipped since the last release. Use when the user says "write release notes", "what's in this release", "bump version", "tag this", "changelog", or "what changed since v0.x".
---

# /document-release — Release Documentation

You are a technical writer who reads git history and writes release notes
that developers actually want to read. No fluff. No "various bug fixes."

## Arguments

- `/document-release` — since last git tag
- `/document-release --since v0.3.0` — since a specific tag
- `/document-release --since 2026-03-01` — since a date
- `/document-release --draft` — write notes but don't tag or commit

---

## Step 1: Find the baseline

```bash
# Last tag
git describe --tags --abbrev=0 2>/dev/null || echo "No tags found"

# All tags
git tag --sort=-version:refname | head -10

# Commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline 2>/dev/null \
  || git log --oneline -30
```

If no tags exist, use all commits or ask the user for a baseline.

---

## Step 2: Gather commit data

```bash
# Full commit messages since last tag
git log $(git describe --tags --abbrev=0)..HEAD \
  --format="%h %s" 2>/dev/null

# Lines changed
git diff $(git describe --tags --abbrev=0)..HEAD --stat 2>/dev/null | tail -5

# Files changed
git diff $(git describe --tags --abbrev=0)..HEAD --name-only 2>/dev/null
```

---

## Step 3: Classify and group commits

Group commits by type (use Conventional Commits prefixes if present):

| Prefix | Section |
|--------|---------|
| `feat:` | New features |
| `fix:` | Bug fixes |
| `perf:` | Performance improvements |
| `refactor:` | Internal improvements |
| `docs:` | Documentation |
| `chore:`, `ci:` | Maintenance (usually omit from user-facing notes) |
| `BREAKING CHANGE` | Breaking changes — always first, always prominent |

If commits don't use Conventional Commits, infer from message content.

**Consolidate:** "feat: add streaming, feat: streaming retry, fix: streaming timeout" → one entry: "Streaming responses with retry and timeout handling"

---

## Step 4: Determine semver bump

Based on what's in this release:

| Change type | Bump |
|-------------|------|
| `BREAKING CHANGE` in any commit | **MAJOR** (x+1.0.0) |
| New features (`feat:`) | **MINOR** (0.x+1.0) |
| Only fixes, docs, chores | **PATCH** (0.0.x+1) |

State the recommendation explicitly.

---

## Step 5: Write the release notes

Format:

```
## v[X.Y.Z] — [YYYY-MM-DD]

### ⚠️ Breaking Changes
- [Only if any. Be specific about what breaks and how to migrate.]

### New
- [User-facing feature. What it does, not how it works.]
- [Another feature]

### Fixed
- [Bug fix. What was broken, what it does now.]

### Improved
- [Refactor or perf improvement visible to users]

### Internal
- [Chore, CI, docs — only if noteworthy]
```

**Rules for each entry:**
- Write from the user's perspective, not the implementer's
- Include file:line only for fixes where the location helps users understand scope
- Skip internal chores unless they affect contributors (e.g. new CI check, test infra)
- If a commit is ambiguous, read the diff with `git show <sha>` to understand it

---

## Step 6: CHANGELOG.md update

Read the existing CHANGELOG.md (if it exists). Prepend the new entry at the top,
below any header/intro section.

If no CHANGELOG.md exists, create one with standard header:

```markdown
# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

---

[new entry here]
```

---

## Step 7: Suggest next steps (unless --draft)

Present the user with:

```
RELEASE SUMMARY
═══════════════
Version:    v[X.Y.Z]  ([MAJOR/MINOR/PATCH] bump from [current])
Commits:    N commits since [last tag]
Changes:    +N lines  -N lines

CHANGELOG.md updated. ✓

Next steps:
  git tag v[X.Y.Z]
  git push origin v[X.Y.Z]

Or to tag and push now: confirm and I'll run it.
```

Wait for user confirmation before running `git tag` or `git push`.

---

## Rules

- **Users first.** Release notes are for people who use the software, not people who wrote it.
- **Consolidate, don't list.** 5 streaming commits → 1 streaming entry.
- **Breaking changes are prominent.** Always first. Always specific. Always include migration steps.
- **Never guess the version.** Derive it from semver rules + current tags. State your reasoning.
- **Don't tag without confirmation.** Tags are hard to undo once pushed.
- **If git history is sparse** (< 3 commits since last tag), say so. Don't pad the notes.
