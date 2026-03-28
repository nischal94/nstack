---
name: context
description: Use when Claude Code feels slow, confused, or repetitive — when it's ignoring instructions, repeating mistakes you've corrected before, or when you want to audit your CLAUDE.md, rules files, and memory for staleness and contradictions. Use when the user says "audit my claude config", "check my context", "why is claude ignoring X", "clean up my rules", or "context health check".
---

# /context — Claude Code Configuration Audit

You are auditing the Claude Code configuration for the current project and user.
Your job: find what's stale, contradictory, missing, or bloated — and surface it.

A healthy Claude Code context makes every session faster and more accurate.
A degraded one causes repeated mistakes, ignored instructions, and confused behavior.

## Arguments

- `/context` — full audit (project CLAUDE.md + global rules + memory)
- `/context --project` — project configuration only
- `/context --global` — global CLAUDE.md and rules only
- `/context --memory` — memory files only
- `/context --fix` — apply safe fixes automatically (reorder, deduplicate); flag the rest

---

## Step 1: Discover all configuration files

```bash
# Project-level
ls CLAUDE.md .claude/CLAUDE.md .claude.local.md 2>/dev/null
find . -name "CLAUDE.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null

# Global
ls ~/.claude/CLAUDE.md ~/.claude/CLAUDE.local.md 2>/dev/null

# Rules
ls ~/.claude/rules/ 2>/dev/null
find . -path "*/.claude/rules/*.md" 2>/dev/null

# Memory
ls ~/.claude/projects/ 2>/dev/null
find ~/.claude/projects/ -name "MEMORY.md" -o -name "*.md" 2>/dev/null | head -20
```

Build an inventory:
```
CONFIGURATION INVENTORY
═══════════════════════
Project CLAUDE.md:      [found / missing]
Global CLAUDE.md:       [found / missing]
Rules files:            N files
Memory files:           N files
```

---

## Step 2: Audit project CLAUDE.md

Read the file fully. Check for:

**Staleness:**
- File paths or directory names that no longer exist in the repo
- Commands that no longer work (build commands, test commands, script names)
- Tech stack descriptions that don't match `package.json`, `pyproject.toml`, etc.
- References to team members, external services, or features that were removed

```bash
# Verify referenced paths exist
# For each path mentioned in CLAUDE.md, check it
ls src/ app/ backend/ frontend/ api/ 2>/dev/null
```

**Contradictions:**
- Two instructions that conflict ("always use X" and "never use X")
- Instructions that contradict the project's actual code style (check a sample file)
- Rules that conflict with global CLAUDE.md

**Missing critical sections:**
- No build/test/run commands → Claude has to guess every session
- No architecture overview → Claude can't navigate the codebase efficiently
- No code style conventions → Claude will be inconsistent
- No "gotchas" section → known pitfalls get hit repeatedly

**Bloat:**
- Verbose explanations of obvious things
- Multiple paragraphs where one sentence would suffice
- Content that belongs in a README, not a CLAUDE.md (historical context, design rationale)

---

## Step 3: Audit global rules files

For each file in `~/.claude/rules/`:

Read it. Check for:

**Path scoping:**
- Does this rule have a `paths:` frontmatter? If not, it applies to every file.
- Does the scope match the content? (A React rule without `paths: ["**/*.tsx"]` fires everywhere)

**Conflicts between rules:**
- Rule A says "always add error handling" → Rule B says "trust internal code"
- Rule A says "use snake_case" → Rule B says "use camelCase" (without path scoping)

**Redundancy:**
- Two rules that say the same thing in different words
- A rule that duplicates something already in project CLAUDE.md

**Dead rules:**
- Rules for a framework no longer used in any project
- Rules referencing tools you no longer use

---

## Step 4: Audit memory files

For each file in `~/.claude/projects/[current-project]/memory/`:

Read it. Check for:

**Staleness:**
- Memories that reference specific files, functions, or variables — verify they still exist
- Project state memories ("currently working on X") that are no longer current
- Date-specific memories that are now outdated

```bash
# Verify memory references exist in codebase
# For each file path mentioned in memory, check it
```

**Accuracy:**
- Feedback memories that say "never do X" — is X actually something Claude should avoid, or was it a one-time correction?
- Reference memories pointing to external URLs or services that may have changed

**Missing memories:**
- Patterns of behavior the user has corrected multiple times but not saved
- Project-specific conventions that come up repeatedly

---

## Step 5: Cross-file consistency check

Check that the same thing isn't said differently in multiple places:

```
CROSS-FILE CONSISTENCY
══════════════════════
Checking: error handling conventions...
  Project CLAUDE.md:   "always use try/catch"
  global rules:        "use explicit error boundaries"  ← same principle, same scope
  → Consolidation opportunity

Checking: commit message format...
  Project CLAUDE.md:   "use Conventional Commits"
  memory/feedback:     "use feat:/fix: prefixes"  ← redundant
  → Memory entry is redundant with CLAUDE.md
```

---

## Step 6: Health report

```
CONTEXT HEALTH REPORT
══════════════════════════
Project CLAUDE.md:    [HEALTHY / ISSUES FOUND]
Global CLAUDE.md:     [HEALTHY / ISSUES FOUND]
Rules files:          [N issues]
Memory files:         [N issues]

ISSUES FOUND
────────────
[S1] STALE — CLAUDE.md:14
     References `src/components/OldComponent.tsx` — file no longer exists
     Fix: remove or update the reference

[S2] STALE — memory/project_state.md
     "Currently building the streaming feature" — streaming was shipped 3 weeks ago
     Fix: delete or archive this memory

[C1] CONTRADICTION — rules/typescript.md vs rules/api-security.md
     typescript.md: "trust internal function return types"
     api-security.md: "validate all inputs including internal"
     These conflict when working on internal API handlers.
     Fix: add path scoping to api-security.md → `app/api/**`

[M1] MISSING — Project CLAUDE.md
     No test command documented. Claude guesses `npm test` or `pytest` every session.
     Fix: add `## Commands` section with `npm run test:watch` (detected from package.json)

[B1] BLOAT — Global CLAUDE.md lines 45-67
     22-line explanation of why to prefer composition over inheritance.
     This is a general principle, not actionable project context.
     Fix: condense to one sentence or remove

SAFE AUTO-FIXES (applied if --fix flag was passed)
──────────────────────────────────────────────────
None applied (re-run with --fix to apply)

RECOMMENDED FIXES (require your review)
────────────────────────────────────────
1. [S1] Remove stale path reference in CLAUDE.md
2. [S2] Delete stale project state memory
3. [C1] Add path scoping to api-security.md
4. [M1] Add Commands section to CLAUDE.md
5. [B1] Condense or remove verbose explanation
```

For each recommended fix, ask for confirmation before applying.

---

## Step 7: Apply fixes (--fix mode or after confirmation)

**Safe auto-fixes** (apply without asking):
- Remove duplicate lines
- Fix broken path references that have obvious replacements
- Add detected missing commands (auto-detected from package.json scripts)

**Confirmation required:**
- Any deletion of memory content
- Any change to CLAUDE.md prose sections
- Any change to rules logic

After applying fixes:
```
FIXES APPLIED
═════════════
[S1] Removed stale path reference — CLAUDE.md:14
[M1] Added Commands section — CLAUDE.md
[B1] Condensed verbose section — global CLAUDE.md lines 45-67 → 1 line

Deferred (your review needed):
[S2] Stale memory — review and delete manually: ~/.claude/projects/.../memory/project_state.md
[C1] Rules conflict — review path scoping: ~/.claude/rules/api-security.md
```

---

## Rules

- **Read every file before reporting anything.** Don't skim and pattern-match.
- **Stale references are the highest priority.** They cause the most confusion per line.
- **Never delete memory without explicit confirmation.** Memory is the user's persistent context — be conservative.
- **Auto-fix only clearly safe changes.** When in doubt, flag for review.
- **Cross-file conflicts are subtle.** The most common confusion source is two rules that seem compatible but fire on the same code.
- **Missing commands are easy wins.** If Claude has to guess the test command every session, that's a fixable inefficiency.
