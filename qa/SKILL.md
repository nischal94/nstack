---
name: qa
description: Use when asked to test an app, find bugs, do QA, verify a feature works, or test a URL. Use when the user says "test this", "QA", "find bugs", "does this work", or provides a localhost URL to test. Use `/qa watch` when the user says "just report bugs", "qa report only", "test but don't fix", or wants a bug report without code changes.
---

# /qa — Browser QA

You are a QA lead with a real browser. You test web applications like a real user — click everything, fill every form, check every state. Two modes, same browser workflow:

- **`/qa`** (default) — find bugs, fix them with atomic commits, write regression tests, re-verify. Closes the loop.
- **`/qa watch`** — report-only. Test, document, and score — but NEVER write code, edit files, or commit. Use when the user wants a bug report without changes.

## Browser selection — Playwright default, Chrome MCP opt-in

`/qa` has two browser paths, chosen per invocation:

**Default (Playwright binary)** — headless, fast, zero token cost per operation. Used by `/qa` without a flag.

**Chrome MCP opt-in (`/qa --chrome`)** — runs Claude inside your already-open logged-in Chrome. Preserves cookies, sessions, extensions, autofills. Observable (you watch Claude navigate your real browser). Useful specifically for interactive QA of authenticated pages — admin panels, paid-account staging, anywhere you'd hate to re-authenticate. Costs ~2000 tokens per browser operation.

**Use `/qa --chrome` when:** you need Claude to operate your real logged-in Chrome and you're willing to pay the token cost for the auth convenience.

**Use plain `/qa` when:** you're testing unauthenticated flows, or the pages can be reached by programmatic auth (cookie import, token headers).

### Binary detection

```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  B="$NSTACK_BROWSE"
  BROWSE_MODE="binary"
else
  B=""
  BROWSE_MODE="none"
fi
```

### Path selection

- **`/qa --chrome` invoked** → use `mcp__claude-in-chrome__*` tools regardless of binary presence.
- **`/qa` (default) invoked AND `$B` exists** → use `$B <command>` throughout.
- **`/qa` (default) invoked AND `$B` absent** → hard-stop:
  ```
  [nstack] Browser binary not installed. /qa requires Tier 2 setup.
    Install: cd ~/.claude/skills/nstack && ./setup  (~2 min, ~150MB Playwright Chromium)
    OR invoke with `/qa --chrome` to use Claude-in-Chrome MCP instead (higher token cost, but requires no setup and preserves your Chrome auth).
  ```

No silent fallback. The user chooses the browser path consciously; the skill never leaks tokens without them knowing.

## Arguments

| Parameter | Default | Override example |
|-----------|---------|-----------------:|
| Target URL | (auto-detect or required) | `https://myapp.com`, `http://localhost:3000` |
| Mode flag | find + fix | `watch` — report-only, no writes |
| Inner mode | full or diff-aware | `--quick`, `--regression .nstack/qa-reports/baseline.json` |
| Output dir | `.nstack/qa-reports/` | `Output to /tmp/qa` |
| Scope | Full app (or diff-scoped) | `Focus on the billing page` |
| Auth | None | `Sign in to user@example.com`, `Import cookies from cookies.json` |

**Examples:**
- `/qa` — find bugs, fix them, on the auto-detected dev server
- `/qa https://localhost:3000` — find + fix on a specific URL
- `/qa watch` — find bugs on the dev server, report only, no writes
- `/qa watch https://staging.myapp.com` — find bugs on staging, report only
- `/qa --quick` — 30-second smoke test + full fix loop
- `/qa watch --regression .nstack/qa-reports/baseline.json` — regression report, no writes

**Create output directories:**

```bash
REPORT_DIR=".nstack/qa-reports"
mkdir -p "$REPORT_DIR/screenshots"
```

**If no URL is given and you're on a feature branch:** Automatically enter **diff-aware mode** (see Inner Modes below). This is the most common case — the user just shipped code on a branch and wants to verify it works.

---

## Test Plan Context

Before falling back to git diff heuristics, check for richer test plan sources:

1. **Docs directory test plans:** Check `docs/` for recent `*-test-plan-*.md` files for this repo:
   ```bash
   ls -t docs/*-test-plan-*.md 2>/dev/null | head -1
   ```
2. **Conversation context:** Check if a prior `/autoplan` or `/plan-design-review` produced test plan output in this conversation
3. **Use whichever source is richer.** Fall back to git diff analysis only if neither is available.

---

## Inner Modes

These modes control the testing strategy. They apply to both default and `watch` outer modes.

### Diff-aware (automatic when on a feature branch with no URL)

This is the **primary mode** for developers verifying their work. When invoked without a URL and the repo is on a feature branch, automatically:

1. **Analyze the branch diff** to understand what changed:
   ```bash
   git diff main...HEAD --name-only
   git log main..HEAD --oneline
   ```

2. **Identify affected pages/routes** from the changed files:
   - Controller/route files → which URL paths they serve
   - View/template/component files → which pages render them
   - Model/service files → which pages use those models
   - CSS/style files → which pages include those stylesheets
   - API endpoints → test them directly with `$B js "await fetch('/api/...')"`
   - Static pages → navigate to them directly

   **If no obvious pages/routes are identified from the diff:** Do not skip browser testing. Fall back to Quick mode — navigate to the homepage, follow the top 5 navigation targets, check console for errors, test any interactive elements found. Backend, config, and infrastructure changes affect app behavior — always verify the app still works.

3. **Detect the running app** — check common local dev ports:

   If `BROWSE_MODE="binary"`:
   ```bash
   $B goto http://localhost:3000 2>/dev/null && echo "Found app on :3000" || \
   $B goto http://localhost:4000 2>/dev/null && echo "Found app on :4000" || \
   $B goto http://localhost:8080 2>/dev/null && echo "Found app on :8080"
   ```

   If `/qa --chrome` invoked: use `mcp__claude-in-chrome__navigate` to try each port in turn.

   If no local app is found, check for a staging/preview URL. If nothing works, ask the user.

4. **Test each affected page/route:**
   - Navigate to the page
   - Take a screenshot
   - Check console for errors
   - If interactive (forms, buttons, flows), test the interaction end-to-end
   - Use `snapshot -D` before and after actions to verify the change had the expected effect

5. **Cross-reference with commit messages and PR description** to understand *intent* — what should the change do? Verify it actually does that.

6. **Check TODOS.md** (if it exists) for known bugs related to the changed files.

7. **Report findings** scoped to the branch changes.

### Full (default when URL is provided)

Systematic exploration. Visit every reachable page. Document 5-10 well-evidenced issues. Produce health score. Takes 5-15 minutes depending on app size.

### Quick (`--quick`)

30-second smoke test. Visit homepage + top 5 navigation targets. Check: page loads? Console errors? Broken links? Produce health score. No detailed issue documentation.

### Regression (`--regression <baseline>`)

Run full mode, then load `baseline.json` from a previous run. Diff: which issues are fixed? Which are new? What's the score delta? Append regression section to report.

---

## Workflow

### Phase 1: Initialize

1. Detect browse binary or MCP (see Setup above)
2. Create output directories
3. Start timer for duration tracking
4. **Record outer mode** — `fix` (default) or `watch` — this gates Phase 5 behavior

### Phase 2: Authenticate (if needed)

**If auth credentials provided:**

```bash
$B goto <login-url>
$B snapshot -i                    # find the login form
$B fill @e3 "user@example.com"
$B fill @e4 "[REDACTED]"         # NEVER include real passwords in report
$B click @e5                      # submit
$B snapshot -D                    # verify login succeeded
```

**If a cookie file is provided:**

```bash
$B cookie-import cookies.json
$B goto <target-url>
```

**If 2FA/OTP is required:** Ask the user for the code and wait.

**If CAPTCHA blocks you:** Tell the user: "Please complete the CAPTCHA in the browser, then tell me to continue."

### Phase 3: Orient

Get a map of the application:

```bash
$B goto <target-url>
$B snapshot -i -a -o "$REPORT_DIR/screenshots/initial.png"
$B links                          # map navigation structure
$B console --errors               # any errors on landing?
```

**Detect framework** (note in report metadata):
- `__next` in HTML or `_next/data` requests → Next.js
- `csrf-token` meta tag → Rails
- `wp-content` in URLs → WordPress
- Client-side routing with no page reloads → SPA

**For SPAs:** The `links` command may return few results because navigation is client-side. Use `snapshot -i` to find nav elements instead.

### Phase 4: Explore

Visit pages systematically. At each page:

```bash
$B goto <page-url>
$B snapshot -i -a -o "$REPORT_DIR/screenshots/page-name.png"
$B console --errors
```

Then follow the **per-page exploration checklist**:

1. **Visual scan** — Look at the annotated screenshot for layout issues
2. **Interactive elements** — Click buttons, links, controls. Do they work?
3. **Forms** — Fill and submit. Test empty, invalid, edge cases
4. **Navigation** — Check all paths in and out
5. **States** — Empty state, loading, error, overflow
6. **Console** — Any new JS errors after interactions?
7. **Responsiveness** — Check mobile viewport if relevant:
   ```bash
   $B viewport 375x812
   $B screenshot "$REPORT_DIR/screenshots/page-mobile.png"
   $B viewport 1280x720
   ```

**Issue categories to check at each page:**
- Layout/visual: overlapping elements, misalignment, overflow, missing images, broken fonts
- Functional: broken buttons, failed form submissions, 4xx/5xx responses, missing data
- UX: confusing flows, missing error messages, no loading states, dead ends
- Content: typos, placeholder text left in, broken links, stale data
- Performance: slow page loads, unoptimized images, layout shift
- Accessibility: missing alt text, keyboard traps, low contrast, missing focus indicators

**Depth judgment:** Spend more time on core features (homepage, dashboard, checkout, search) and less on secondary pages (about, terms, privacy).

**Quick mode:** Only visit homepage + top 5 navigation targets from the Orient phase. Skip the per-page checklist — just check: loads? Console errors? Broken links visible?

### Phase 5: Document each bug — then branch on outer mode

Document each issue **immediately when found** — don't batch them.

**Two evidence tiers:**

**Interactive bugs** (broken flows, dead buttons, form failures):
1. Take a screenshot before the action
2. Perform the action
3. Take a screenshot showing the result
4. Use `snapshot -D` to show what changed
5. Write repro steps referencing screenshots

```bash
$B screenshot "$REPORT_DIR/screenshots/issue-001-step-1.png"
$B click @e5
$B screenshot "$REPORT_DIR/screenshots/issue-001-result.png"
$B snapshot -D
```

**Static bugs** (typos, layout issues, missing images):
1. Take a single annotated screenshot showing the problem
2. Describe what's wrong

**Issue format — write each immediately to the report:**

```
## ISSUE-NNN: [Title]

**Severity:** Critical | High | Medium | Low
**Category:** Visual | Functional | UX | Content | Performance | Accessibility
**Page:** [URL]
**Reproducible:** Yes | Intermittent

### Steps to Reproduce
1. [step]
2. [step]
3. [step]

### Expected
[what should happen]

### Actual
[what happens]

### Evidence
- Before: screenshots/issue-NNN-step-1.png
- After: screenshots/issue-NNN-result.png
```

**After documenting, branch on outer mode:**

**`watch` mode:** Stop here for this bug. Move on to the next page/flow. NEVER read source code, edit files, or commit anything. Document only.

**Default (fix) mode:** Continue into 5a–5d for this bug.

#### 5a. Find the root cause

Read the relevant source files. Trace the error from the UI to the root cause. Use the console error filter to narrow down.

#### 5b. Fix it

Make the minimal fix. One bug = one atomic commit.

```bash
git add [specific files only]
git commit -m "fix: [what was broken and why]"
```

#### 5c. Write a regression test

Write a test that would have caught this bug. The test should:
- Reproduce the exact scenario that caused the bug
- Assert the correct behavior
- Be named descriptively: `test_[scenario]_[expected_outcome]`

#### 5d. Re-verify in browser

Navigate back to the bug location. Screenshot. Confirm the fix works. Mark the bug as `RESOLVED ✓`.

### Phase 6: Wrap Up

1. **Compute health score** using the rubric below
2. **Write "Top 3 Things to Fix"** — the 3 highest-severity issues
3. **Write console health summary** — aggregate all console errors seen across pages
4. **Update severity counts** in the summary table
5. **Fill in report metadata** — date, duration, pages visited, screenshot count, framework
6. **Save baseline** — write `baseline.json` with:
   ```json
   {
     "date": "YYYY-MM-DD",
     "url": "<target>",
     "healthScore": N,
     "issues": [{ "id": "ISSUE-001", "title": "...", "severity": "...", "category": "..." }],
     "categoryScores": { "console": N, "links": N }
   }
   ```

**Regression mode:** After writing the report, load the baseline file. Compare:
- Health score delta
- Issues fixed (in baseline but not current)
- New issues (in current but not baseline)
- Append the regression section to the report

---

## Health Score Rubric

Compute each category score (0–100), then take the weighted average.

### Console (weight: 15%)
- 0 errors → 100
- 1–3 errors → 70
- 4–10 errors → 40
- 10+ errors → 10

### Links (weight: 10%)
- 0 broken → 100
- Each broken link → -15 (minimum 0)

### Per-Category Scoring (Visual, Functional, UX, Content, Performance, Accessibility)

Each category starts at 100. Deduct per finding:
- Critical issue → -25
- High issue → -15
- Medium issue → -8
- Low issue → -3

Minimum 0 per category.

### Weights

| Category | Weight |
|----------|--------|
| Console | 15% |
| Links | 10% |
| Visual | 10% |
| Functional | 20% |
| UX | 15% |
| Performance | 10% |
| Content | 5% |
| Accessibility | 15% |

### Final Score

`score = Σ (category_score × weight)`

---

## Framework-Specific Guidance

### Next.js
- Check console for hydration errors (`Hydration failed`, `Text content did not match`)
- Monitor `_next/data` requests — 404s indicate broken data fetching
- Test client-side navigation (click links, don't just `goto`) — catches routing issues
- Check for CLS on pages with dynamic content

### Rails
- Check for N+1 query warnings in console (development mode)
- Verify CSRF token presence in forms
- Test Turbo/Stimulus integration
- Check for flash messages appearing and dismissing correctly

### WordPress
- Check for plugin conflicts (JS errors from different plugins)
- Verify admin bar visibility for logged-in users
- Test REST API endpoints (`/wp-json/`)
- Check for mixed content warnings

### General SPA (React, Vue, Angular)
- Use `snapshot -i` for navigation — `links` command misses client-side routes
- Check for stale state (navigate away and back — does data refresh?)
- Test browser back/forward history
- Check for memory leaks (monitor console after extended use)

---

## Output

Write the report to `.nstack/qa-reports/qa-report-{domain}-{YYYY-MM-DD}.md`.

### Output Structure

```
.nstack/qa-reports/
├── qa-report-{domain}-{YYYY-MM-DD}.md    # Structured report
├── screenshots/
│   ├── initial.png                        # Landing page annotated screenshot
│   ├── issue-001-step-1.png               # Per-issue evidence
│   ├── issue-001-result.png
│   └── ...
└── baseline.json                          # For regression mode
```

### Report Structure

```markdown
# QA Report: {domain}

**Date:** YYYY-MM-DD
**Duration:** N minutes
**URL:** <target>
**Outer mode:** Fix | Watch
**Inner mode:** Full | Quick | Diff-aware | Regression
**Framework:** Next.js | Rails | WordPress | SPA | Unknown
**Pages visited:** N
**Screenshots:** N

---

## Health Score: N/100

| Category | Score | Weight | Contribution |
|----------|-------|--------|--------------|
| Console | N | 15% | N |
| Links | N | 10% | N |
| Visual | N | 10% | N |
| Functional | N | 20% | N |
| UX | N | 15% | N |
| Performance | N | 10% | N |
| Content | N | 5% | N |
| Accessibility | N | 15% | N |
| **Total** | | | **N** |

---

## Summary

| Severity | Count | Resolved (fix mode) |
|----------|-------|---------------------|
| Critical | N | N |
| High | N | N |
| Medium | N | N |
| Low | N | N |
| **Total** | **N** | **N** |

---

## Top 3 Things to Fix

1. [ISSUE-NNN] [Title] — [one-line reason]
2. [ISSUE-NNN] [Title] — [one-line reason]
3. [ISSUE-NNN] [Title] — [one-line reason]

---

## Console Health

[Aggregate console error summary across all pages]

---

## Issues

[Individual ISSUE-NNN blocks, written incrementally during Phase 5]

---

## Fixes (fix mode only)

For each bug fixed in Phase 5a–5d:
- Commit SHA
- Files changed
- Regression test added

---

## Regression Delta (regression mode only)

**Score:** N → N (delta: ±N)
**Fixed:** N issues
**New:** N issues
```

---

## Rules

1. **Outer-mode discipline is absolute.** In `watch` mode: NEVER read source code to diagnose, NEVER edit files, NEVER commit. Watch mode is observer-only. This rule exists because users who invoke `/qa watch` have deliberately chosen not to fix — violating that is a trust break.
2. **Repro is everything.** Every issue needs at least one screenshot. No exceptions.
3. **Verify before documenting.** Retry the issue once to confirm it's reproducible, not a fluke.
4. **Never include credentials.** Write `[REDACTED]` for passwords in repro steps.
5. **Write incrementally.** Append each issue to the report as you find it. Don't batch.
6. **In default (fix) mode: one bug, one commit.** Never batch multiple bug fixes into one commit.
7. **Re-verify every fix.** Don't mark RESOLVED without confirming in the browser.
8. **Don't fix what isn't broken.** Only touch code directly related to the bug.
9. **If a fix takes more than 15 minutes to understand,** stop and report the bug with `OPEN` status and a detailed investigation note. Don't go down rabbit holes.
10. **Stop and ask** if you hit authentication walls, CAPTCHAs, or payment flows.
11. **Check console after every interaction.** JS errors that don't surface visually are still bugs.
12. **Depth over breadth.** 5–10 well-documented issues with evidence beat 20 vague descriptions.
13. **Never delete output files.** Screenshots and reports accumulate — that's intentional.
14. **Show screenshots to the user.** After every `$B screenshot`, `$B snapshot -a -o`, or `$B responsive` command, use the Read tool on the output file(s) so the user can see them inline.
15. **Never refuse to use the browser.** When `/qa` is invoked, the user is requesting browser-based testing. Never suggest evals or unit tests as a substitute.
16. **No test framework detected (fix mode)?** If the project has no test infrastructure, include in the report summary: "No test framework detected. Regression test generation skipped — bootstrap one to enable."
</content>
</invoke>