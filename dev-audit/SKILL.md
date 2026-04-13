---
name: dev-audit
description: Use when asked to "audit the DX", "test the developer experience", "review the onboarding", "how hard is it to get started", or after shipping a developer-facing feature. Requires ./setup for browser screenshots.
---

# /dev-audit — Live Developer Experience Audit

You are a DX engineer dogfooding a live developer product. Not reviewing a plan. Not reading about the experience. **Testing it.**

Use the browse binary for screenshots and navigation. Use bash for CLI commands and file inspection. Measure, don't guess. State your evidence source for every score.

---

## Browser Setup

```bash
B=""
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$_ROOT" ] && [ -x "$_ROOT/browse/dist/browse" ] && B="$_ROOT/browse/dist/browse"
[ -z "$B" ] && [ -x "$HOME/.claude/skills/nstack/browse/dist/browse" ] && B="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

If `NEEDS_SETUP`: tell the user "Browser binary not found. Run `cd ~/.claude/skills/nstack && ./setup` to enable screenshots (~2 min). Without it, audit proceeds without screenshots — scores marked INFERRED." Then continue without screenshots. Do not stop.

---

## DX First Principles

Every recommendation traces back to one of these:

1. **Zero friction at T0.** First five minutes decide everything. Hello world without reading docs.
2. **Incremental steps.** Never force developers to understand the whole system before getting value from one part.
3. **Learn by doing.** Playgrounds, sandboxes, copy-paste code that works in context.
4. **Decide for me, let me override.** Opinionated defaults. Escape hatches required.
5. **Fight uncertainty.** Every error = problem + cause + fix.
6. **Show code in context.** Hello world is a lie. Show real auth, real error handling, real deployment.
7. **Speed is a feature.** Iteration speed is everything.
8. **Create magical moments.** What would feel like magic? Make it the first thing developers experience.

---

## Scoring Rubric (0-10)

| Score | Meaning |
|---|---|
| 9-10 | Best-in-class. Stripe/Vercel tier. Developers rave about it. |
| 7-8 | Good. Usable without frustration. Minor gaps. |
| 5-6 | Acceptable. Works but with friction. Developers tolerate it. |
| 3-4 | Poor. Developers complain. Adoption suffers. |
| 1-2 | Broken. Developers abandon after first attempt. |
| 0 | Not addressed. No thought given to this dimension. |

**The gap method:** For each score, explain what a 10 looks like for THIS product. Then recommend fixes toward 10.

---

## TTHW Benchmarks (Time to Hello World)

| Tier | Time | Impact |
|---|---|---|
| Champion | < 2 min | 3-4x higher adoption |
| Competitive | 2-5 min | Baseline |
| Needs Work | 5-10 min | Significant drop-off |
| Red Flag | > 10 min | 50-70% abandon |

---

## Step 0: Scope Declaration

Ask the user (AskUserQuestion):

> What are we auditing?
> A) This project — I'll read the repo, docs, and CLI
> B) An external URL — provide the docs/product URL

If B: ask for the URL. If A: read CLAUDE.md and README.md to discover docs URL, install command, and API/CLI surface.

Also check for a prior `/dev-audit` score in `.claude/dev-history.jsonl` — if found, display it as the baseline for comparison.

---

## Step 0.5: Boomerang Baseline — plan vs reality

This is the most valuable signal in a live DX audit: comparing what the plan claimed to deliver against what actually shipped. If a prior `/plan-dev-review` ran on this repo, its projected scores and TTHW estimates become the baseline we measure reality against.

```bash
# Look for prior plan-dev-review output in docs/ or the plan file itself
ls -t docs/plan-dev-review-*.md 2>/dev/null | head -1
grep -l "Developer Experience Review" docs/*.md 2>/dev/null | head -5
```

If a plan-dev-review output is found, extract:
- The target persona (from Step 0A of the plan review)
- The target TTHW tier (from Step 0C)
- The target magical-moment delivery vehicle (from Step 0D)
- The per-pass projected scores (1-8)

Display a Boomerang table inline at the top of this audit's output:

```
BOOMERANG (plan vs reality)
═══════════════════════════
Dimension             | Plan said   | Reality       | Delta
Target persona        | [planned]   | [seen today]  | [match / drift]
Target TTHW           | < N min     | measured N m  | ±N min
Magical moment        | [vehicle]   | [what ships]  | [present / absent / different]
Getting Started       | N/10        | N/10          | ±N
API/CLI Design        | N/10        | N/10          | ±N
Error Messages        | N/10        | N/10          | ±N
... (one row per pass)
```

Flag with `🟢 on-track`, `🟡 minor drift`, `🔴 plan-missed` per row. The plan-missed rows become the highest-priority recommendations in the final output.

If no plan-dev-review output exists for this repo, note "No prior plan — running first-time audit; next run becomes the boomerang baseline."

Skip this step silently if neither prior audit history nor plan output exists.

---

## Step 1: Getting Started Audit

**What to test:** Can a new developer reach a working hello world without help?

```bash
# Read install instructions
cat README.md | head -100
```

If browser available: navigate to the docs/landing page. Screenshot it.

Map the getting-started steps:

```
GETTING STARTED AUDIT
=====================
Step 1: [what dev does]    Time: [est]   Friction: [low/med/high]   Evidence: [source]
Step 2: [what dev does]    Time: [est]   Friction: [low/med/high]   Evidence: [source]
...
TOTAL: [N steps, M minutes]
TTHW tier: [Champion / Competitive / Needs Work / Red Flag]
```

**Gold standard:** Stripe — one key, one curl, working response. No account required to see the API work.

Score 0-10. For anything below 8: name the exact friction point and what a fix looks like.

---

## Step 2: API / CLI / SDK Ergonomics Audit

**What to test:** Is the interface intuitive? Consistent? Discoverable?

```bash
# CLI: run --help and subcommand --help
<cli-name> --help 2>&1 | head -60
<cli-name> <subcommand> --help 2>&1 | head -40

# API: check naming consistency
grep -r "function\|export\|def " src/ --include="*.ts" --include="*.py" | head -30
```

If browser available and API playground exists: navigate and screenshot it.

Evaluate:
- Flag design (short flags, long flags, consistent naming)
- Naming consistency across the API surface
- Error output quality when called incorrectly
- Discoverability — can you guess the next command?

**Gold standard:** kubectl — consistent `<verb> <noun>` pattern throughout.

Score 0-10.

---

## Step 3: Error Message Audit

**What to test:** When things go wrong, does the error explain what happened, why, and how to fix it?

```bash
# Trigger common errors via bash where possible
<cli-name> --invalid-flag 2>&1
<cli-name> <command> --missing-required-arg 2>&1
```

If browser available: navigate to 404 pages. Screenshot. Try submitting invalid forms if possible.

Score each error against the three-tier model:
- **Tier 1 (best):** Problem + cause + fix + docs link
- **Tier 2:** Problem + cause
- **Tier 3 (worst):** Problem only, or cryptic code

**Gold standard:** Rust compiler — names the exact line, explains why it's wrong, suggests the fix.

Score 0-10.

---

## Step 4: Documentation Audit

**What to test:** Can developers find what they need in under 2 minutes?

If browser available: navigate the docs. Screenshot the home page and search results for 3 common queries.

Evaluate:
- Search functionality — does it return relevant results?
- Code examples — are they copy-paste complete, or do they require assembly?
- Information architecture — can you find what you need without reading everything?
- Language switcher — if multi-language, does switching break context?
- Freshness — do examples match the current API?

**Gold standard:** Stripe Docs — every code example runs as-is. Language switcher preserves context.

Score 0-10.

---

## Step 5: Upgrade Path Audit

**What to test:** Will upgrading break production? Does the project make upgrades boring?

```bash
# Read changelog and migration guides
cat CHANGELOG.md 2>/dev/null | head -80
ls docs/migration* docs/upgrade* 2>/dev/null
grep -r "deprecated\|@deprecated\|DEPRECATED" src/ --include="*.ts" --include="*.py" | head -20
```

Evaluate:
- CHANGELOG quality — user-facing, clear, grouped by semver impact
- Migration guides — do they exist? Are they step-by-step?
- Deprecation warnings — are they in the code before removal?

**Gold standard:** Next.js — codemods for breaking changes, clear migration guides, deprecation warnings before removal.

Score 0-10. Evidence: INFERRED from files.

---

## Step 6: Developer Environment Audit

**What to test:** How hard is it to set up a local dev environment?

```bash
cat README.md | grep -A 30 -i "install\|setup\|getting started\|requirements"
ls .env.example .env.sample docker-compose* Makefile 2>/dev/null
cat package.json | jq '.scripts' 2>/dev/null
```

Evaluate:
- Prerequisites listed and versioned
- Setup steps count and complexity
- `.env.example` exists with all required vars
- `make dev` or equivalent one-command local start
- Platform coverage (macOS/Linux/Windows)

**Gold standard:** Supabase — `supabase start` spins up the full stack locally in one command.

Score 0-10. Evidence: INFERRED from files.

---

## Step 7: Community & Ecosystem Audit

**What to test:** Where do developers go when they're stuck? Is help available?

```bash
# Check issue templates and contributing guide
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
cat CONTRIBUTING.md 2>/dev/null | head -40
```

If browser available: navigate GitHub issues/discussions. Screenshot the issues page.

Evaluate:
- Community links (Discord, Slack, GitHub Discussions)
- Issue response time (check last 5 open issues)
- Issue templates — structured or blank?
- Stack Overflow presence (search if browser available)
- Contributing guide — does it lower the bar for first contributions?

Score 0-10.

---

## Step 8: DX Measurement Audit

**What to test:** Does the project measure developer experience, or guess at it?

```bash
# Check for feedback mechanisms
grep -r "feedback\|NPS\|survey\|telemetry" docs/ README.md 2>/dev/null | head -10
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
```

If browser available: check for feedback widgets or NPS prompts in the product.

Evaluate:
- Bug report templates (structured vs blank)
- User feedback mechanisms
- Analytics on docs pages
- Any stated DX goals or metrics in CONTRIBUTING.md

Score 0-10. Evidence: INFERRED from files.

---

## DX Scorecard

```
DX SCORECARD
============
Product:  <name>
Audited:  <date>
Auditor:  nstack /dev-audit

Pass                        Score   Status        Evidence
--------------------------  -----   -----------   --------
1. Getting Started          __/10   [TESTED]      [screenshots/bash]
2. API/CLI/SDK Ergonomics   __/10   [TESTED]      [screenshots/bash]
3. Error Messages           __/10   [TESTED]      [bash output]
4. Documentation            __/10   [TESTED]      [screenshots]
5. Upgrade Path             __/10   [INFERRED]    [files]
6. Developer Environment    __/10   [INFERRED]    [files]
7. Community & Ecosystem    __/10   [TESTED]      [screenshots]
8. DX Measurement           __/10   [INFERRED]    [files]

COMPOSITE DX SCORE: __ / 10
TTHW: [Champion / Competitive / Needs Work / Red Flag] — [N min]
```

Evidence labels:
- `TESTED` — navigated or executed directly
- `INFERRED` — derived from reading files
- `PARTIAL` — some dimensions tested, some inferred

---

## Priority Recommendations

After the scorecard, output the top 3 highest-impact fixes — ordered by (score gap × developer impact):

```
TOP 3 FIXES
===========
1. [Pass name] — Score: X/10 → Target: Y/10
   Problem: [specific friction point]
   Fix: [concrete change, with file or URL if applicable]
   Why it matters: [adoption or retention impact]
   Plan alignment: [on-track / drifted from plan / new regression]

2. ...

3. ...
```

Never give generic advice. Every recommendation must cite a specific finding from the audit.

---

## Persist to History

Append one JSONL line to `.claude/dev-history.jsonl`:

```bash
mkdir -p .claude
echo '{"ts":"<ISO8601>","target":"<product name or URL>","score":<composite>,"getting_started":<n>,"api_cli":<n>,"errors":<n>,"docs":<n>,"upgrade":<n>,"dev_env":<n>,"community":<n>,"measurement":<n>,"tthw_minutes":<n>}' >> .claude/dev-history.jsonl
```

Set any skipped passes to `null`.

---

## Completion Status

When reporting the audit result, end with one of these status labels — not a prose summary:

- **DONE** — All 8 passes evaluated with evidence. Scorecard, Top 3 Fixes, and Boomerang (if applicable) all produced.
- **DONE_WITH_CONCERNS** — Audit completed but specific dimensions lacked evidence. List which passes were INFERRED vs TESTED and why, and list any findings you're only moderately confident in.
- **BLOCKED** — Cannot complete the audit. State what is blocking (e.g., "product requires paid account to reach hello world", "CLI requires a runtime not present on this machine") and what was attempted.
- **NEEDS_CONTEXT** — Missing information required to continue. State exactly what you need from the user.

Escalation is always OK. Bad work is worse than no work. You will not be penalized for escalating. If you have attempted a pass three times without clear evidence, STOP and escalate via DONE_WITH_CONCERNS or BLOCKED.

---

## Rules

- **Measure, don't guess.** Every score needs evidence — screenshot, bash output, or file citation
- **Never say "consider" without a specific recommendation** — name the file, the line, the change
- **INFERRED scores are valid** — but label them clearly; don't pretend you tested what you read
- **One pass at a time** — complete each pass fully before moving to the next
- **If browser is unavailable** — continue with bash and file inspection; mark all browser-dependent passes as INFERRED
- **Boomerang first, scores second.** If a plan-dev-review output exists, display the Boomerang table at the top — plan-vs-reality drift is the single highest-signal finding and should be visible before the per-pass scores
- **End with status, not prose.** DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT — parseable by downstream workflows
