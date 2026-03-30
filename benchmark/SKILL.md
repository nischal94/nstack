---
name: benchmark
description: Use when asked about "performance", "benchmark", "page speed", "web
  vitals", "bundle size", or "load time". Establishes performance baselines and
  detects regressions. Compares before/after metrics. (nstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

## Binary detection — nstack browse CLI

```bash
# Binary detection — nstack browse CLI
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  B="$NSTACK_BROWSE"
  BROWSE_MODE="binary"
else
  B=""
  BROWSE_MODE="mcp"
  echo "[nstack] Browser binary not installed. Using Claude-in-Chrome MCP (slower, more token-intensive)."
  echo "  For faster rendering: cd ~/.claude/skills/nstack && ./setup"
fi
```

When `BROWSE_MODE="binary"`: use `$B <command>`.
When `BROWSE_MODE="mcp"`: use `mcp__claude-in-chrome__*` MCP tools.

# /benchmark — Performance Regression Detection

You are a **Performance Engineer** who has optimized apps serving millions of requests. You know that performance doesn't degrade in one big regression — it dies by a thousand paper cuts. Each PR adds 50ms here, 20KB there, and one day the app takes 8 seconds to load and nobody knows when it got slow.

Your job is to measure, baseline, compare, and alert. You use the browse daemon's `perf` command and JavaScript evaluation to gather real performance data from running pages.

## User-invocable
When the user types `/benchmark`, run this skill.

## Arguments
- `/benchmark <url>` — full performance audit with baseline comparison
- `/benchmark <url> --baseline` — capture baseline (run before making changes)
- `/benchmark <url> --quick` — single-pass timing check (no baseline needed)
- `/benchmark <url> --pages /,/dashboard,/api/health` — specify pages
- `/benchmark --diff` — benchmark only pages affected by current branch
- `/benchmark --trend` — show performance trends from historical data

## Instructions

### Phase 1: Setup

```bash
mkdir -p .nstack/benchmarks
mkdir -p .nstack/benchmarks/baselines
```

### Phase 2: Page Discovery

Auto-discover pages from navigation or use `--pages` to specify them explicitly.

If no `--pages` provided:
```bash
# Binary mode
$B goto <base-url>
$B links
# MCP mode: use mcp__claude-in-chrome__navigate then mcp__claude-in-chrome__get_page_text to extract links
```

Extract all navigation links and unique page paths. Deduplicate and normalize to absolute URLs. Limit to the top 10 most important pages (homepage, key user flows) unless `--pages` specifies more.

If `--diff` mode:
```bash
git diff $(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)...HEAD --name-only
```

### Phase 3: Performance Data Collection

For each page, collect comprehensive performance metrics.

Binary mode:
```bash
$B goto <page-url>
$B perf
```

`$B perf` returns a JSON object with keys: `ttfb`, `fcp`, `lcp`, `domInteractive`, `domComplete`, `loadTime` (all in ms), plus `transferSize` (bytes). Use these fields directly for metric extraction.

MCP mode: `$B perf` has no direct equivalent — use `mcp__claude-in-chrome__navigate` to load the page, then use `mcp__claude-in-chrome__javascript_tool` to evaluate the navigation timing API directly:
```js
JSON.stringify((() => {
  const n = performance.getEntriesByType('navigation')[0];
  return {
    ttfb: Math.round(n.responseStart - n.requestStart),
    domInteractive: Math.round(n.domInteractive - n.startTime),
    domComplete: Math.round(n.domComplete - n.startTime),
    loadTime: Math.round(n.loadEventEnd - n.startTime),
    transferSize: n.transferSize
  };
})())
```
For FCP/LCP in MCP mode, also eval `JSON.stringify(performance.getEntriesByType('paint'))`.

Resource analysis (both modes):

Binary mode:
```bash
$B eval "JSON.stringify(performance.getEntriesByType('resource').map(r => ({name: r.name.split('/').pop().split('?')[0], type: r.initiatorType, size: r.transferSize, duration: Math.round(r.duration)})).sort((a,b) => b.duration - a.duration).slice(0,15))"
```

MCP mode: use `mcp__claude-in-chrome__javascript_tool` with the same JS expression.

Bundle size check:

Binary mode:
```bash
$B eval "JSON.stringify(performance.getEntriesByType('resource').filter(r => r.initiatorType === 'script').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})))"
$B eval "JSON.stringify(performance.getEntriesByType('resource').filter(r => r.initiatorType === 'css').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})))"
```

MCP mode: use `mcp__claude-in-chrome__javascript_tool` with the same JS expressions.

Network summary:

Binary mode:
```bash
$B eval "(() => { const r = performance.getEntriesByType('resource'); return JSON.stringify({total_requests: r.length, total_transfer: r.reduce((s,e) => s + (e.transferSize||0), 0), by_type: Object.entries(r.reduce((a,e) => { a[e.initiatorType] = (a[e.initiatorType]||0) + 1; return a; }, {})).sort((a,b) => b[1]-a[1])})})()"
```

MCP mode: use `mcp__claude-in-chrome__javascript_tool` with the same JS expression.

### Phase 4: Baseline Capture (--baseline mode)

Save metrics to baseline file:

```json
{
  "url": "<url>",
  "timestamp": "<ISO>",
  "branch": "<branch>",
  "pages": {
    "/": {
      "ttfb_ms": 120,
      "fcp_ms": 450,
      "lcp_ms": 800,
      "dom_interactive_ms": 600,
      "dom_complete_ms": 1200,
      "full_load_ms": 1400,
      "total_requests": 42,
      "total_transfer_bytes": 1250000,
      "js_bundle_bytes": 450000,
      "css_bundle_bytes": 85000,
      "largest_resources": [
        {"name": "main.js", "size": 320000, "duration": 180},
        {"name": "vendor.js", "size": 130000, "duration": 90}
      ]
    }
  }
}
```

Write to `.nstack/benchmarks/$(date +%Y-%m-%d)-baseline.json`.

This uses the same naming scheme as benchmark reports so `--trend` mode (which globs `.nstack/benchmarks/*.json`) discovers both baselines and full benchmark runs.

### Phase 5: Comparison

If baseline exists, compare current metrics against it:

```
PERFORMANCE REPORT — [url]
══════════════════════════
Branch: [current-branch] vs baseline ([baseline-branch])

Page: /
─────────────────────────────────────────────────────
Metric              Baseline    Current     Delta    Status
────────            ────────    ───────     ─────    ──────
TTFB                120ms       135ms       +15ms    OK
FCP                 450ms       480ms       +30ms    OK
LCP                 800ms       1600ms      +800ms   REGRESSION
DOM Interactive     600ms       650ms       +50ms    OK
DOM Complete        1200ms      1350ms      +150ms   WARNING
Full Load           1400ms      2100ms      +700ms   REGRESSION
Total Requests      42          58          +16      WARNING
Transfer Size       1.2MB       1.8MB       +0.6MB   REGRESSION
JS Bundle           450KB       720KB       +270KB   REGRESSION
CSS Bundle          85KB        88KB        +3KB     OK

REGRESSIONS DETECTED: 3
  [1] LCP doubled (800ms → 1600ms) — likely a large new image or blocking resource
  [2] Total transfer +50% (1.2MB → 1.8MB) — check new JS bundles
  [3] JS bundle +60% (450KB → 720KB) — new dependency or missing tree-shaking
```

**Regression thresholds:**
- Timing metrics: >50% increase OR >500ms absolute increase = REGRESSION
- Timing metrics: >20% increase = WARNING
- Bundle size: >25% increase = REGRESSION
- Bundle size: >10% increase = WARNING
- Request count: >30% increase = WARNING

### Phase 6: Slowest Resources

```
TOP 10 SLOWEST RESOURCES
═════════════════════════
#   Resource                  Type      Size      Duration
1   vendor.chunk.js          script    320KB     480ms
2   main.js                  script    250KB     320ms
3   hero-image.webp          img       180KB     280ms
4   analytics.js             script    45KB      250ms    ← third-party
5   fonts/inter-var.woff2    font      95KB      180ms
...

RECOMMENDATIONS:
- vendor.chunk.js: Consider code-splitting — 320KB is large for initial load
- analytics.js: Load async/defer — blocks rendering for 250ms
- hero-image.webp: Add width/height to prevent CLS, consider lazy loading
```

### Phase 7: Performance Budget

Check against industry budgets:

```
PERFORMANCE BUDGET CHECK
════════════════════════
Metric              Budget      Actual      Status
────────            ──────      ──────      ──────
FCP                 < 1.8s      0.48s       PASS
LCP                 < 2.5s      1.6s        PASS
Total JS            < 500KB     720KB       FAIL
Total CSS           < 100KB     88KB        PASS
Total Transfer      < 2MB       1.8MB       WARNING (90%)
HTTP Requests       < 50        58          FAIL

Grade: B (4/6 passing)
```

### Phase 8: Trend Analysis (--trend mode)

Load historical baseline files and show trends:

```
PERFORMANCE TRENDS (last 5 benchmarks)
══════════════════════════════════════
Date        FCP     LCP     Bundle    Requests    Grade
2026-03-10  420ms   750ms   380KB     38          A
2026-03-12  440ms   780ms   410KB     40          A
2026-03-14  450ms   800ms   450KB     42          A
2026-03-16  460ms   850ms   520KB     48          B
2026-03-18  480ms   1600ms  720KB     58          B

TREND: Performance degrading. LCP doubled in 8 days.
       JS bundle growing 50KB/week. Investigate.
```

### Phase 9: Save Report

Use `date +%Y-%m-%d` for the filename date (e.g. `2026-03-31`). Write to:
- `.nstack/benchmarks/$(date +%Y-%m-%d)-benchmark.md`
- `.nstack/benchmarks/$(date +%Y-%m-%d)-benchmark.json`

The `--trend` mode uses `Glob` to discover historical files: pattern `.nstack/benchmarks/*.json` sorted by filename (which sorts chronologically given `YYYY-MM-DD` prefix).

## Important Rules

- **Measure, don't guess.** Use actual performance.getEntries() data, not estimates.
- **Baseline is essential.** Without a baseline, you can report absolute numbers but can't detect regressions. Always encourage baseline capture.
- **Relative thresholds, not absolute.** 2000ms load time is fine for a complex dashboard, terrible for a landing page. Compare against YOUR baseline.
- **Third-party scripts are context.** Flag them, but the user can't fix Google Analytics being slow. Focus recommendations on first-party resources.
- **Bundle size is the leading indicator.** Load time varies with network. Bundle size is deterministic. Track it religiously.
- **Read-only.** Produce the report. Don't modify code unless explicitly asked.
