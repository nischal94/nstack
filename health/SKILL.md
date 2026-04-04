---
name: health
description: Use when asked for a "health check", "code quality score", "how healthy is the codebase", or "run all checks". Auto-detects project tools (type checker, linter, test runner, dead code, shell linter), scores each category, and tracks trend over time.
---

# /health — Code Health Dashboard

Runs every available quality tool in the project, scores each category 0-10, and produces a composite health score. Tracks trend across runs.

---

## Step 1: Detect Health Stack

Check CLAUDE.md for an existing `## Health Stack` section. If found, use those tools and skip auto-detection.

If not found, auto-detect:

```bash
# Type checker
[ -f tsconfig.json ] && echo "TYPECHECK: tsc --noEmit"

# Linter
[ -f biome.json ] || [ -f biome.jsonc ] && echo "LINT: biome check ."
ls eslint.config.* .eslintrc.* .eslintrc 2>/dev/null | head -1 | xargs -I{} echo "LINT: eslint ."
[ -f pyproject.toml ] && grep -q "ruff" pyproject.toml 2>/dev/null && echo "LINT: ruff check ."
[ -f pyproject.toml ] && grep -q "pylint" pyproject.toml 2>/dev/null && echo "LINT: pylint ."

# Test runner
[ -f package.json ] && grep -q '"test"' package.json 2>/dev/null && echo "TEST: npm test"
[ -f bun.lock ] || [ -f bun.lockb ] && grep -q '"test"' package.json 2>/dev/null && echo "TEST: bun test"
[ -f pyproject.toml ] && grep -q "pytest" pyproject.toml 2>/dev/null && echo "TEST: pytest"
[ -f Cargo.toml ] && echo "TEST: cargo test"
[ -f go.mod ] && echo "TEST: go test ./..."

# Dead code
command -v knip >/dev/null 2>&1 && echo "DEADCODE: knip"
[ -f package.json ] && grep -q '"knip"' package.json 2>/dev/null && echo "DEADCODE: npx knip"

# Shell linting
command -v shellcheck >/dev/null 2>&1 && echo "SHELL: shellcheck"
```

Also run `Glob` for `**/*.sh` to find shell scripts to lint.

Present detected tools and ask:

> I detected these health check tools:
> - Type check: `tsc --noEmit`
> - Lint: `biome check .`
> - Tests: `bun test`
> - Dead code: `knip`
> - Shell lint: `shellcheck`
>
> A) Looks right — persist to CLAUDE.md and run
> B) Adjust tools — tell me what to change
> C) Just run — don't persist

If A or B (after adjustments), append to CLAUDE.md:

```markdown
## Health Stack

- typecheck: tsc --noEmit
- lint: biome check .
- test: bun test
- deadcode: knip
- shell: shellcheck **/*.sh
```

---

## Step 2: Run Tools

Run each tool sequentially. For each:

```bash
START=$(date +%s)
<tool command> 2>&1 | tail -50
EXIT_CODE=$?
END=$(date +%s)
echo "TOOL:<name> EXIT:$EXIT_CODE DURATION:$((END-START))s"
```

If a tool is missing or not installed: mark as `SKIPPED`, not failed.

---

## Step 3: Score Each Category

| Category | Weight | 10 | 7 | 4 | 0 |
|---|---|---|---|---|---|
| Type check | 25% | Clean (exit 0) | <10 errors | <50 errors | ≥50 errors |
| Lint | 20% | Clean (exit 0) | <5 warnings | <20 warnings | ≥20 warnings |
| Tests | 30% | All pass (exit 0) | >95% pass | >80% pass | ≤80% pass |
| Dead code | 15% | Clean (exit 0) | <5 unused | <20 unused | ≥20 unused |
| Shell lint | 10% | Clean (exit 0) | <5 issues | ≥5 issues | — |

**Parsing counts:**
- `tsc`: count lines matching `error TS`
- `biome`/`eslint`/`ruff`: count error/warning lines or parse summary
- Tests: parse pass/fail counts; if only exit code available, use exit 0 = 10, non-zero = 4
- `knip`: count lines reporting unused exports, files, or dependencies
- `shellcheck`: count distinct findings (lines starting with `In ... line`)

**Composite:**
```
composite = (typecheck * 0.25) + (lint * 0.20) + (test * 0.30) + (deadcode * 0.15) + (shell * 0.10)
```

If a category is skipped, redistribute its weight proportionally among the remaining categories.

---

## Step 4: Present Dashboard

```
CODE HEALTH DASHBOARD
=====================
Project: <name>
Branch:  <branch>
Date:    <today>

Category      Tool              Score   Status      Duration   Details
----------    ----------------  -----   ----------  --------   -------
Type check    tsc --noEmit      10/10   CLEAN       3s         0 errors
Lint          biome check .      8/10   WARNING     2s         3 warnings
Tests         bun test          10/10   CLEAN       12s        47/47 passed
Dead code     knip               7/10   WARNING     5s         4 unused exports
Shell lint    shellcheck        10/10   CLEAN       1s         0 issues

COMPOSITE SCORE: 9.1 / 10
Duration: 23s total
```

Status labels: `CLEAN` (10) · `WARNING` (7-9) · `NEEDS WORK` (4-6) · `CRITICAL` (0-3)

For any category below 7, show the top issues from that tool's output.

---

## Step 5: Persist to Health History

Append one JSONL line to `.claude/health-history.jsonl` in the project root:

```bash
mkdir -p .claude
echo '{"ts":"<ISO8601>","branch":"<branch>","score":<composite>,"typecheck":<n>,"lint":<n>,"test":<n>,"deadcode":<n>,"shell":<n>,"duration_s":<n>}' >> .claude/health-history.jsonl
```

Set skipped categories to `null`.

---

## Step 6: Trend Analysis

Read the last 10 entries from `.claude/health-history.jsonl`:

```bash
tail -10 .claude/health-history.jsonl 2>/dev/null || echo "NO_HISTORY"
```

If prior entries exist:

```
HEALTH TREND (last 5 runs)
==========================
Date          Branch         Score   TC   Lint  Test  Dead  Shell
----------    -----------    -----   --   ----  ----  ----  -----
2026-03-28    main           9.4     10   9     10    8     10
2026-03-31    main           9.1     10   8     10    7     10

Trend: DECLINING (-0.3 since last run)
```

Trend labels: `IMPROVING` · `STABLE` (±0.2) · `DECLINING`

If declining in a specific category, call it out with a specific recommendation — not generic advice.

---

## Rules

- **Never fail silently** — if a tool errors unexpectedly, show the error and mark it `ERROR` (not `SKIPPED`)
- **SKIPPED ≠ failure** — missing tools don't penalize the score
- **No install suggestions** — if a tool isn't present, note it as optional, don't prompt to install
- **Specific over generic** — when recommending fixes, cite the exact file and line from tool output
