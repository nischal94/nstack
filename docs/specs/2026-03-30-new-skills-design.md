# New Skills + /cso Update Design

**Date:** 2026-03-30
**Status:** Approved
**Scope:** Spec B — 9 new skills + `/cso` update. Browser infrastructure is Spec A (complete).

---

## Problem

nstack covers security, QA, and retrospectives well. It's missing the design cluster (visual generation, design review, design system creation), monitoring (performance baselines, post-deploy canary), and two workflow skills (report-only QA, YC-style office hours). gstack v0.13.4 has all of these. nstack should port them rather than invent from scratch — the logic is proven, and the porting approach is already established from Spec A.

`/cso` also lags behind gstack: it's missing skill supply chain scanning and trend tracking across audit runs.

---

## Approach

Full port from gstack with systematic stripping. Every gstack-specific reference is replaced or removed:

| Remove | Replace with |
|---|---|
| Full preamble block (~40 lines) | Binary detection block (browser skills only) |
| `gstack-update-check` | nothing |
| `~/.gstack/` paths | `~/.nstack/` or `.nstack/` |
| `/plan-ceo-review`, `/plan-eng-review` | `superpowers:writing-plans` |
| conductor pattern | `Agent` tool with parallel dispatch |
| `(gstack)` in description | `(nstack)` |
| `<!-- AUTO-GENERATED -->` comment | nothing |
| telemetry, session tracking | nothing |
| `gstack-config` binary calls | nothing |

After porting each skill: `grep -rn 'gstack\|GSTACK' <skill>/SKILL.md` — zero matches required before commit.

---

## Binary Detection Block

All 7 browser-dependent skills include this block before any skill logic:

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

When `BROWSE_MODE="binary"`: all browser operations use `$B <command>`.
When `BROWSE_MODE="mcp"`: all browser operations use `mcp__claude-in-chrome__*` MCP tools.

If binary absent AND MCP unavailable:
```
[nstack] No browser available. Design skills require either:
  1. nstack browser binary: cd ~/.claude/skills/nstack && ./setup
  2. Claude-in-Chrome MCP running in this session
```

---

## New Skills

### `/office-hours`

**What it does:** Two modes. Startup mode: six YC-style forcing questions (demand reality, status quo, desperate specificity, narrowest wedge, direct observation, future-fit). Builder mode: design thinking for side projects, hackathons, and open source.

**No browser dependency.** Pure text skill.

**Triggers:** "brainstorm this", "I have an idea", "is this worth building", "office hours", "help me think through this". Proactively invoked when user describes a new product idea or wants to explore a concept before any code is written.

**Output:** Structured Q&A, then a design doc saved to `docs/`.

**Source:** Port from `garrytan/gstack/office-hours/SKILL.md` — strip preamble, strip gstack references.

---

### `/qa-only`

**What it does:** Report-only QA. Systematically tests a web application and produces a structured report with health score, screenshots, and repro steps. Never fixes anything — reports only.

**Browser dependency:** Yes (binary or MCP).

**Triggers:** "just report bugs", "qa report only", "test but don't fix". Proactively suggest when user wants a bug report without code changes.

**Output:** Structured health report with severity-bucketed findings, screenshots, repro steps. Score 0–100.

**Source:** Port from `garrytan/gstack/qa-only/SKILL.md`.

---

### `/benchmark`

**What it does:** Performance regression detection. Establishes baselines for page load times, Core Web Vitals, and resource sizes. Compares before/after. Tracks trends over time.

**Browser dependency:** Yes (binary or MCP).

**Triggers:** "performance", "benchmark", "page speed", "web vitals", "bundle size", "load time".

**Storage:** Baselines saved to `.nstack/benchmarks/` (gitignored via `.nstack/`).

**Output:** Baseline report, or diff vs previous baseline showing regressions.

**Source:** Port from `garrytan/gstack/benchmark/SKILL.md`.

---

### `/canary`

**What it does:** Post-deploy canary monitoring. Watches the live app for console errors, performance regressions, and page failures. Takes periodic screenshots, compares against pre-deploy baselines, alerts on anomalies.

**Browser dependency:** Yes (binary or MCP).

**Triggers:** "monitor deploy", "canary", "post-deploy check", "watch production", "verify deploy".

**Storage:** Pre-deploy snapshots saved to `.nstack/canary/` (gitignored via `.nstack/`).

**Output:** Monitoring report with anomaly alerts and before/after screenshot comparisons.

**Source:** Port from `garrytan/gstack/canary/SKILL.md`.

---

### `/design`

**What it does:** Generate a complete UI from scratch. Reads the codebase, proposes a design system, generates multiple HTML variants, screenshots each, picks the best, and applies it to the project.

**Browser dependency:** Yes (binary or MCP — binary strongly recommended; variant generation is 4–6 screenshots per run).

**Triggers:** "design this", "make it look good", "generate UI", "build the frontend".

**Parallel variant generation:** Uses `Agent` tool to generate variants in parallel (replaces gstack's conductor pattern).

**Source:** Port from `garrytan/gstack/design/SKILL.md` — strip conductor pattern, replace with Agent tool.

---

### `/design-consultation`

**What it does:** Interactive design system creation. Researches the landscape, proposes aesthetic/typography/color/layout/spacing/motion, generates font+color preview pages, writes `DESIGN.md` as the project's design source of truth.

**Browser dependency:** Yes (binary or MCP — for preview page screenshots).

**Triggers:** "design system", "brand guidelines", "create DESIGN.md". Proactively suggest when starting a new project's UI with no existing design system.

**Output:** `DESIGN.md` committed to project root, preview screenshots saved.

**Source:** Port from `garrytan/gstack/design-consultation/SKILL.md`.

---

### `/design-review`

**What it does:** Designer's eye visual QA. Screenshots the live app, finds visual inconsistencies, spacing issues, hierarchy problems, and AI slop patterns. Fixes them in source code with atomic commits and re-verifies with before/after screenshots.

**Browser dependency:** Yes (binary or MCP).

**Triggers:** "audit the design", "visual QA", "check if it looks good", "design polish". Proactively suggest when user mentions visual inconsistencies.

**Source:** Port from `garrytan/gstack/design-review/SKILL.md`.

---

### `/design-shotgun`

**What it does:** Generate multiple design variants of an existing component or page, open a comparison board, collect structured feedback, and iterate.

**Browser dependency:** Yes (binary or MCP — binary strongly recommended; shotgun generates 4–6 variants).

**Triggers:** "explore designs", "show me options", "design variants", "visual brainstorm", "I don't like how this looks". Proactively suggest when user describes a UI feature but hasn't seen what it could look like.

**Parallel variant generation:** Uses `Agent` tool for parallel generation (replaces gstack's conductor pattern).

**Source:** Port from `garrytan/gstack/design-shotgun/SKILL.md`.

---

### `/plan-design-review`

**What it does:** Designer's eye plan review — plan-mode only (before implementation). Rates each design dimension 0–10, explains what a 10 looks like, then fixes the plan to get there.

**No browser dependency** — works on plan documents, not live pages.

**Triggers:** "review the design plan", "design critique". Proactively suggest when user has a plan with UI/UX components.

**Distinction from `/design-review`:** `/design-review` audits a live running site. `/plan-design-review` audits a written plan before any code is written.

**Source:** Port from `garrytan/gstack/plan-design-review/SKILL.md`.

---

## `/cso` Update

Two additions to the existing `cso/SKILL.md`:

### Skill supply chain scanning

New Phase 8a (inserted between dependency audit and CI/CD). Also accessible via `--skills` flag, and automatically included in `--comprehensive` mode.

Scans all SKILL.md files reachable from `.claude/skills/` for:
- Prompt injection vectors in skill descriptions (instructions that override Claude's behavior)
- Overly broad tool permissions (`allowed-tools: "*"` or equivalent)
- Skills fetching remote URLs at invocation time without validation
- Untrusted skill sources (no known registry attribution)

Each finding includes: skill path, issue type, severity, concrete risk.

### Trend tracking

**At start of run:** Read `.nstack/cso-history/latest.json` if present. Extract previous finding counts by severity.

**At end of run:** Write results to `.nstack/cso-history/YYYY-MM-DD-HH-MM.json` and symlink/copy to `latest.json`.

**Trend diff shown in report:**
```
TREND vs last run (2026-03-25)
  CRITICAL  0 → 0   (no change)
  HIGH      3 → 2   (↓ 1 resolved)
  MEDIUM    5 → 7   (↑ 2 new)
  LOW       2 → 2   (no change)
```

**JSON format** (minimal — no code content, just metadata):
```json
{
  "date": "2026-03-30",
  "findings": {
    "CRITICAL": 0,
    "HIGH": 2,
    "MEDIUM": 7,
    "LOW": 2
  },
  "titles": ["Prompt injection in api/chat.py:34", "..."]
}
```

Files live in `.nstack/cso-history/` — already gitignored via `.nstack/`.

---

## Repository Changes

**New files (9 skills):**
```
office-hours/SKILL.md
qa-only/SKILL.md
benchmark/SKILL.md
canary/SKILL.md
design/SKILL.md
design-consultation/SKILL.md
design-review/SKILL.md
design-shotgun/SKILL.md
plan-design-review/SKILL.md
```

**Modified files:**
```
cso/SKILL.md          ← add Phase 8a (skill supply chain) + trend tracking
CLAUDE.md             ← add 9 new skill entries
README.md             ← add 9 new rows to skills table + update skill count
```

---

## Non-Goals

- No `design-html` skill — internal gstack utility; logic inlined in design skills
- No `plan-ceo-review` or `plan-eng-review` — covered by `/autoplan` + `superpowers:writing-plans`
- No `gstack-upgrade` equivalent — nstack users `git pull`
- No `learn` skill — nstack uses Claude's built-in persistent memory system
- No `codex` skill — gstack-specific meta-skill
- No conductor pattern — replaced by `Agent` tool
- No telemetry, session tracking, or update checks
- No `connect-chrome` or `setup-browser-cookies` — gstack install utilities
- No Windows/Linux support for browser binary (macOS only, inherited from Spec A)
