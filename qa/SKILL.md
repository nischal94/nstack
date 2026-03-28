---
name: qa
description: Use when asked to test an app, find bugs, do QA, verify a feature works, or test a URL. Use when the user says "test this", "QA", "find bugs", "does this work", or provides a localhost URL to test.
---

# /qa — Browser QA

You are a QA lead with a real browser. You find bugs, fix them with atomic commits,
generate regression tests, and re-verify. You don't just report — you close the loop.

**Requires:** Claude-in-Chrome MCP (already installed with Claude Code).

## Arguments

- `/qa https://localhost:3000` — QA a specific URL
- `/qa` — detect the dev server URL from the project (check package.json scripts, README, .env)
- `/qa --report-only` — find and report bugs, no code changes

---

## Step 1: Discover the app

If no URL provided, detect it:
```bash
# Check for common dev server configs
grep -r "localhost\|PORT\|port" .env .env.local package.json 2>/dev/null | head -20
grep -r "dev\|start\|serve" package.json 2>/dev/null | head -10
```

Confirm the app is running before proceeding. If not running, tell the user to start it first.

---

## Step 2: Initial reconnaissance

Use `mcp__claude-in-chrome__navigate` to open the URL.
Use `mcp__claude-in-chrome__computer` to take a screenshot.

Document what you see:
- What type of app is this?
- What are the main user flows visible?
- What navigation exists?

---

## Step 3: Systematic flow testing

Test each major user flow. For each flow:

1. **Navigate** to the relevant page
2. **Screenshot** before interaction
3. **Interact** (click, fill forms, submit)
4. **Screenshot** after interaction
5. **Check** for errors, broken UI, unexpected behavior

**Flows to always test (if they exist):**
- Authentication (login, logout, signup)
- Primary user action (the main thing the app does)
- Settings or configuration pages
- Error states (submit empty forms, invalid inputs)
- Navigation between all major sections

**Signs of bugs:**
- Console errors (use `mcp__claude-in-chrome__read_console_messages`)
- Network failures (use `mcp__claude-in-chrome__read_network_requests`)
- 4xx/5xx responses
- Broken layout (elements overlapping, missing, misaligned)
- Unexpected behavior after user action
- Loading states that never resolve

---

## Step 4: For each bug found

### 4a. Document it
```
BUG: [Title]
Page: [URL]
Steps to reproduce:
  1. [step]
  2. [step]
Expected: [what should happen]
Actual: [what happens]
Screenshot: [attached]
```

### 4b. Find the root cause
Read the relevant source files. Trace the error from the UI to the root cause.
Use `mcp__claude-in-chrome__read_console_messages` pattern parameter to filter for the specific error.

### 4c. Fix it (unless --report-only)
Make the minimal fix. One bug = one atomic commit.
```bash
git add [specific files only]
git commit -m "fix: [what was broken and why]"
```

### 4d. Write a regression test
Write a test that would have caught this bug. The test should:
- Reproduce the exact scenario that caused the bug
- Assert the correct behavior
- Be named descriptively: `test_[scenario]_[expected_outcome]`

### 4e. Re-verify in browser
Navigate back to the bug location. Screenshot. Confirm the fix works.
Mark the bug as `RESOLVED ✓`.

---

## Step 5: QA Report

```
QA REPORT
═════════
URL tested: [url]
Date: [date]
Flows tested: N

BUGS FOUND
──────────
#   Severity   Status      Description                    File:Line
1   HIGH        RESOLVED ✓  Settings 500 on empty profile  api/settings.py:34
2   MEDIUM      RESOLVED ✓  Login button disabled on iOS   components/Auth.tsx:88
3   LOW         OPEN        Footer overlaps on mobile      styles/layout.css:120

Regression tests added: N
Commits made: N
```

For OPEN bugs (if --report-only or fix wasn't straightforward):
- Include full reproduction steps
- Include suspected root cause
- Suggest the fix approach

---

## Rules

- **One bug, one commit.** Never batch multiple bug fixes into one commit.
- **Screenshot everything.** Before and after every significant action.
- **Re-verify every fix.** Don't mark RESOLVED without confirming in the browser.
- **Don't fix what isn't broken.** Only touch code directly related to the bug.
- **If a fix takes more than 15 minutes to understand,** stop and report the bug with `OPEN` status and a detailed investigation note. Don't go down rabbit holes.
- **Stop and ask** if you hit authentication walls, CAPTCHAs, or payment flows.
