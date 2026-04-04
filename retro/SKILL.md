---
name: retro
description: Use when asked for a retrospective, weekly summary, what shipped, engineering stats, or to reflect on recent work. Use when the user says "retro", "what did we ship", "weekly summary", "how much did I build", or "what did I work on".
---

# /retro — Weekly Retrospective

You are an engineering manager reviewing the week's work with a founder building at speed.
No fluff. Just: what shipped, what the numbers say, and what to focus on next.

## Arguments

- `/retro` — this week (last 7 days)
- `/retro --month` — this month (last 30 days)
- `/retro --since 2026-03-01` — since a specific date
- `/retro --project /path/to/project` — specific project (default: current directory)

---

## Step 1: Gather git stats

```bash
# Commits in period
git log --oneline --since="7 days ago" 2>/dev/null
git log --oneline --since="7 days ago" --format="%h %s" | wc -l

# Lines added/removed
git log --since="7 days ago" --pretty=tformat: --numstat 2>/dev/null | \
  awk '{add+=$1; del+=$2} END {print "Added: "add" Deleted: "del" Net: "add-del}'

# Files most touched
git log --since="7 days ago" --pretty=tformat: --name-only 2>/dev/null | \
  sort | uniq -c | sort -rn | head -10

# Authors (for team repos)
git log --since="7 days ago" --format="%an" | sort | uniq -c | sort -rn

# Commit message summary
git log --since="7 days ago" --format="%s" 2>/dev/null
```

---

## Step 2: Gather test health

```bash
# Test count trend (compare current vs 1 week ago)
# Try common test runners
python -m pytest --co -q 2>/dev/null | tail -5 || \
npx jest --listTests 2>/dev/null | wc -l || \
find . -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | grep -v node_modules | wc -l

# Coverage if available
cat coverage/coverage-summary.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('Coverage:', d['total']['lines']['pct'], '%')" 2>/dev/null || true
```

---

## Step 3: Check Claude Code session logs

```bash
# Claude Code session activity
ls -lt ~/.claude/logs/ 2>/dev/null | head -20
# Count sessions in period
find ~/.claude/logs/ -newer $(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d 2>/dev/null || echo "2000-01-01") -name "*.jsonl" 2>/dev/null | wc -l
```

---

## Step 4: Check for open /cso findings

```bash
ls .nstack/security-reports/ 2>/dev/null | tail -5
cat .nstack/security-reports/*.json 2>/dev/null | python3 -c "
import json, sys, glob
findings = []
for f in glob.glob('.nstack/security-reports/*.json'):
    try:
        d = json.load(open(f))
        findings.extend([x for x in d.get('findings', []) if x.get('status') != 'RESOLVED'])
    except: pass
print(f'Open security findings: {len(findings)}')
for f in findings[:5]:
    print(f'  [{f[\"severity\"]}] {f[\"title\"]}')
" 2>/dev/null || true
```

---

## Step 5: Produce the retrospective

Format:

```
RETRO — WEEK OF [date]
══════════════════════

SHIPPED
───────
[Extract from commit messages — group by theme, not by commit]
✓ [feature/fix/improvement]
✓ [feature/fix/improvement]
...

NUMBERS
───────
Commits:      N
Lines added:  N  deleted: N  net: ±N
Files most touched:
  - path/to/file.py  (N commits)
  - path/to/other.ts (N commits)
Claude Code sessions: N

TEST HEALTH
───────────
Tests: N (±N from last week if determinable)
Coverage: N% (if available)
New regression tests: N (from /qa sessions)

OPEN ITEMS
──────────
Security findings: N open  (run /cso to audit)
  [list HIGH/CRITICAL if any]

FOCUS FOR NEXT WEEK
───────────────────
[1-3 observations based on what the data shows — not generic advice]
[E.g.: "3 open HIGH security findings from last /cso run — worth closing before shipping more features"]
[E.g.: "files/api/chat.py touched 8 times — high churn, consider refactor"]
[E.g.: "net +1,435 lines, 0 new tests — test coverage likely dropped"]
```

---

## Rules

- **Numbers first, narrative second.** Lead with the stats, not the story.
- **Extract themes from commit messages**, don't list them verbatim. "feat: add streaming, feat: add streaming retry, fix: streaming timeout" → "✓ Streaming responses with retry and timeout handling"
- **"Focus for next week" must be data-driven.** Only observations the numbers actually support. No generic "keep shipping" advice.
- **If git history is sparse** (< 3 commits), say so honestly. Don't pad the report.
- **If no test data is available,** note it and suggest running the test suite.
