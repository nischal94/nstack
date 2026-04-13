---
name: land
description: Use when a PR is open and you want to wait for CI, merge it, wait for the deploy, and verify the production health check. Use when the user says "land this", "merge and deploy", "ship to prod", "merge the PR", "deploy this", or after /ship has opened a PR.
---

# /land — Merge, Deploy, Verify

You are a deployment engineer. The PR is open. Your job: get it to production
safely — wait for CI, merge, wait for deploy, verify the site is healthy.

**Prerequisite:** A PR must already be open. If not, run `/ship` first.

**Requires:** `gh` CLI available in the environment.

## Arguments

- `/land` — detect the open PR from current branch and land it
- `/land 123` — land a specific PR number
- `/land --url https://myapp.com` — run health check against this URL after deploy
- `/land --dry-run` — show what would happen without doing it

---

## Step 1: Find the PR

```bash
# Detect PR from current branch
gh pr view --json number,title,state,url,baseRefName,headRefName,checksTotal,checksFailing

# Or list open PRs if not on a feature branch
gh pr list --state open
```

If no PR found: stop. Tell the user to run `/ship` first.
If multiple PRs found: list them and ask which to land.

Output:
```
PR FOUND
════════
#123  feat: add streaming responses
Base: main ← feat/streaming
URL:  https://github.com/owner/repo/pull/123
```

---

## Step 2: Pre-merge gate

Before doing anything irreversible, run a readiness check:

```bash
# CI check status
gh pr checks 123

# Merge conflict check
gh pr view 123 --json mergeable,mergeStateStatus
```

**Gate rules:**
- If CI is still running → wait (Step 3)
- If CI has failed → **stop**. List which checks failed. Do not merge.
- If merge conflicts exist → **stop**. Tell the user to resolve conflicts first.
- If PR is in draft state → **stop**. Ask whether to mark it ready first.

---

## Step 3: Wait for CI

If CI is running, poll until it completes:

```bash
# Watch CI in real time
gh pr checks 123 --watch
```

Show a status line every 30 seconds:
```
[CI] Waiting... 1m 30s elapsed (5 checks running)
[CI] Waiting... 2m 00s elapsed (3 checks running)
[CI] All checks passed ✓
```

Timeout after 15 minutes. If CI hasn't completed: stop, report status, ask whether to continue waiting.

If any check fails after waiting: **stop**. List the failed checks with their log URLs.

---

## Step 4: Final confirmation

Before merging, show a summary and ask for confirmation:

```
READY TO MERGE
══════════════
PR:      #123 — feat: add streaming responses
Base:    main
CI:      ✓ all checks passed
Conflicts: none

Merge strategy: squash (auto-detected from repo settings)

Merge now? (yes / no)
```

Wait for explicit confirmation. Do not merge without it.

---

## Step 5: Merge

```bash
# Auto-detect merge strategy from repo settings
gh pr merge 123 --squash --delete-branch
# or --merge or --rebase depending on repo settings
```

Detect the repo's preferred merge strategy:
```bash
gh api repos/{owner}/{repo} --jq '.allow_squash_merge, .allow_merge_commit, .allow_rebase_merge'
```

Prefer squash if available (cleaner history for fast-moving founders).
If the user has a preference, honor it.

After merge:
```
MERGED ✓
════════
PR #123 merged to main
Branch feat/streaming deleted
```

---

## Step 5a: First-run deploy config (if missing)

Before waiting for the deploy, check whether this repo has its deploy configuration persisted in `CLAUDE.md`. If not, detect and capture it once so every future `/land` invocation skips this step.

```bash
grep -q "## Deploy configuration" CLAUDE.md 2>/dev/null && echo "CONFIG_PRESENT" || echo "CONFIG_MISSING"
```

If `CONFIG_MISSING`: detect the platform, production URL, and health-check endpoint, then offer to persist. This is a one-time setup, not a per-run prompt.

### Detect platform

```bash
# In order of specificity
[ -f fly.toml ] && echo "PLATFORM=fly"
[ -f vercel.json ] || [ -d .vercel ] && echo "PLATFORM=vercel"
[ -f railway.toml ] || [ -f railway.json ] && echo "PLATFORM=railway"
[ -f render.yaml ] && echo "PLATFORM=render"
[ -f netlify.toml ] && echo "PLATFORM=netlify"
[ -f Procfile ] && echo "PLATFORM=heroku"
ls .github/workflows/ 2>/dev/null | grep -iE "deploy|release|prod" && echo "PLATFORM=github-actions"
```

### Detect production URL

For each platform, the canonical URL pattern:
- Fly.io: `<app>.fly.dev` where `<app>` is `grep '^app' fly.toml | head -1`
- Vercel: read `.vercel/project.json` for `projectId` → `gh api` or fall back to asking
- Railway / Render / Netlify: read config file for `url` / `domain` / `serviceName`
- Heroku: `<app>.herokuapp.com` from `heroku apps:info`
- GitHub Actions / custom: ask the user

### Detect health-check endpoint

```bash
# Common health-check paths in code
grep -rE "/health|/healthz|/ping|/status" --include="*.py" --include="*.ts" --include="*.js" --include="*.go" --include="*.rs" -l | head -5
```

Pick the most common one in the codebase; default to `/health` if none found.

### Offer to persist

Use AskUserQuestion:

> "First `/land` run — I didn't find deploy configuration in CLAUDE.md. Here's what I detected:
>
> Platform: [detected]
> Production URL: [detected]
> Health-check endpoint: [detected]
>
> A) Persist this config to CLAUDE.md so future /land runs skip this step
> B) Use this config for this run only (don't persist)
> C) Let me correct it — I'll tell you what's wrong"

If A: append to `CLAUDE.md`:

```markdown
## Deploy configuration

- **Platform:** [detected]
- **Production URL:** [detected]
- **Health-check endpoint:** [detected]
- **Deploy status command:** [detected, e.g. `fly status`, `vercel inspect`]

(Managed by `/land`. Edit here to update.)
```

Commit the CLAUDE.md change separately (`docs: add deploy configuration for /land`).

If B: proceed without persisting. Skip the commit.

If C: ask which field is wrong, correct it, then re-offer A/B.

---

## Step 6: Wait for deploy

Detect the deploy platform and wait for it:

```bash
# Check for GitHub Actions deploy workflows
gh run list --branch main --limit 5

# Watch the deploy run
gh run watch <run-id>
```

**Platform detection** (check in order):
```bash
# Vercel
cat vercel.json .vercel/project.json 2>/dev/null

# Fly.io
cat fly.toml 2>/dev/null

# Railway
cat railway.toml railway.json 2>/dev/null

# Render
cat render.yaml 2>/dev/null

# Netlify
cat netlify.toml 2>/dev/null

# Generic: look for deploy workflow
ls .github/workflows/ 2>/dev/null | grep -i "deploy\|release\|prod"
```

Show deploy progress:
```
[Deploy] Detected: Vercel (via vercel.json)
[Deploy] Watching GitHub Actions deploy workflow...
[Deploy] 30s — build in progress
[Deploy] 90s — deploying to Vercel
[Deploy] Deploy complete ✓ (1m 47s)
```

If no deploy automation detected: skip to Step 7 with a note.

Timeout: 10 minutes. If deploy hasn't finished: report status and ask whether to continue.

---

## Step 7: Production health check

Once deployed (or after merge if no deploy automation):

```bash
# Basic HTTP health check
curl -s -o /dev/null -w "%{http_code} %{time_total}s" https://your-app.com/
curl -s -o /dev/null -w "%{http_code} %{time_total}s" https://your-app.com/api/health
```

If `--url` was provided: use that URL.
If not: try to detect the production URL from:
- `vercel.json` or `.vercel/` config
- `fly.toml` (app name → `<app>.fly.dev`)
- README for a live URL
- Ask the user if none found

**Health check criteria:**
- HTTP 200 → healthy
- HTTP 4xx/5xx → unhealthy, report and offer rollback
- Response time > 5s → warn (possible cold start or performance regression)

Check 3 times with 10s gaps before declaring healthy (avoids cold-start false alarms).

---

## Step 8: Land report

```
LANDED ✓
═════════════════════════════════════════
PR:       #123 — feat: add streaming responses
Merged:   main ← feat/streaming (squash)
Deploy:   Vercel — 1m 47s
Health:   ✓ 200 OK (0.34s) — https://myapp.com

Total time: 4m 12s
```

If health check failed:

```
DEPLOY UNHEALTHY ✗
══════════════════
Health check: 500 Internal Server Error
URL: https://myapp.com

Options:
A) Roll back — revert the merge commit and redeploy
B) Investigate — run /investigate to find the cause
C) Monitor — check again manually in 2 minutes
```

Wait for the user's choice.

---

## Rules

- **Never merge without CI passing.** No exceptions, no flags to skip it.
- **Never merge without explicit confirmation.** Show the summary and wait.
- **Health check failures trigger a rollback offer, not silence.** A bad deploy is worse than a delayed one.
- **Timeouts are stops, not retries.** If CI or deploy takes too long, surface it and ask.
- **Prefer squash merges for fast-moving founders.** Clean main history matters.
- **If anything is ambiguous, ask once.** Don't guess which PR, which URL, or which merge strategy.
