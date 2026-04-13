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

### 1a. AI-assisted commit split

Founder-scale teams building with AI typically have 20–40% of commits AI-authored. Separating that signal is a real productivity metric.

```bash
# Commits with Claude co-author signature
git log --since="7 days ago" --format="%s%n%b" 2>/dev/null | \
  grep -c "Co-Authored-By: Claude\|noreply@anthropic.com" || echo "0"

# As a ratio of total commits
TOTAL=$(git log --since="7 days ago" --format="%h" 2>/dev/null | wc -l)
AI=$(git log --since="7 days ago" --format="%s%n%b" 2>/dev/null | \
  grep -c "Co-Authored-By: Claude\|noreply@anthropic.com" || echo "0")
echo "AI-authored ratio: $AI / $TOTAL"
```

If the repo does not use AI co-author attribution, skip this section silently. Do not speculate or invent ratios.

### 1b. Shipping streak

Track consecutive days with commits — a simple-but-real momentum signal.

```bash
# Commit days in the last 30 days, counted backward from today
for i in $(seq 0 29); do
  DATE=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "${i} days ago" +%Y-%m-%d 2>/dev/null)
  COUNT=$(git log --since="$DATE 00:00" --until="$DATE 23:59" --format="%h" 2>/dev/null | wc -l | tr -d ' ')
  [ "$COUNT" -gt 0 ] && echo "$DATE"
done | head -30
```

From the output, compute:
- **Current streak:** consecutive days-with-commits ending today (0 if today had no commits)
- **Longest streak in period:** longest consecutive-days run seen

For team repos, ALSO compute the streak per author (using `git log --author="<name>"` in the day loop). Present the top 3.

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

## Step 3a: Backlog health (TODOS.md if present)

If a `TODOS.md` exists at the repo root, analyze backlog deltas for the period.

```bash
# Current open items by priority marker
if [ -f TODOS.md ]; then
  grep -c "^- \[ \].*P0" TODOS.md 2>/dev/null || echo "0"
  grep -c "^- \[ \].*P1" TODOS.md 2>/dev/null || echo "0"
  grep -c "^- \[ \].*P2" TODOS.md 2>/dev/null || echo "0"
  grep -c "^- \[ \]" TODOS.md 2>/dev/null || echo "0"

  # Items closed this period (checked off in TODOS.md via a commit in the window)
  git log --since="7 days ago" -p -- TODOS.md 2>/dev/null | \
    grep "^+.*\[x\]" | wc -l
fi
```

From the output, compute:
- **Open now:** count by priority (P0 / P1 / P2) and total
- **Closed this period:** items flipped from `[ ]` to `[x]` in commits during the window
- **Delta:** opened-minus-closed (was the backlog getting shorter or longer?)

If no `TODOS.md` exists, skip this section silently.

---

## Step 3b: Week-over-week trends (windows ≥ 14 days)

When the window is 14+ days (e.g., `--month`, or `--since` with a range longer than a week), split into weekly buckets and show per-bucket deltas.

```bash
# Example for a 4-week window: run git log for each week independently
for week in 0 1 2 3; do
  START=$(date -v-$(( (week+1) * 7 ))d +%Y-%m-%d 2>/dev/null || date -d "$(( (week+1) * 7 )) days ago" +%Y-%m-%d)
  END=$(date -v-$(( week * 7 ))d +%Y-%m-%d 2>/dev/null || date -d "$(( week * 7 )) days ago" +%Y-%m-%d)
  COMMITS=$(git log --since="$START" --until="$END" --format="%h" 2>/dev/null | wc -l | tr -d ' ')
  LINES=$(git log --since="$START" --until="$END" --pretty=tformat: --numstat 2>/dev/null | \
    awk '{add+=$1; del+=$2} END {print add+del}')
  echo "Week $((week+1))  ($START → $END):  $COMMITS commits  $LINES touched-lines"
done
```

Present as a mini-table inside the retro output so inflection points are visible:

```
WEEK-OVER-WEEK (4-week window)
Week 1:  [commits]  [lines]   Notes: [observation if notable]
Week 2:  [commits]  [lines]   [observation]
Week 3:  [commits]  [lines]   [observation]
Week 4:  [commits]  [lines]   [observation]
```

Flag inflections: velocity drop (> 30% fewer commits week-over-week), velocity spike (> 2× commits), or sudden line-count jump without matching commit count (big-change commits).

For windows < 14 days, skip this section silently.

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
Commits:      N   (AI-authored: N / N  = N%)
Lines added:  N  deleted: N  net: ±N
Files most touched:
  - path/to/file.py  (N commits)
  - path/to/other.ts (N commits)
Claude Code sessions: N

SHIPPING CADENCE
────────────────
Current streak:  N days with commits ending today
Longest streak:  N days (in period)
[For team repos, top 3 authors by streak]

BACKLOG HEALTH  (only if TODOS.md exists)
──────────────
Open now:        N   (P0: N, P1: N, P2: N)
Closed period:   N items flipped to done
Delta:           [growing / shrinking / flat] by N items

TEST HEALTH
───────────
Tests: N (±N from last week if determinable)
Coverage: N% (if available)
New regression tests: N (from /qa sessions)

WEEK-OVER-WEEK  (only if window ≥ 14 days)
──────────────
[Per-week table from Step 3b, with inflection flags]

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
