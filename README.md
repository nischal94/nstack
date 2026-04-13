# nstack

> "I don't think I've typed like a line of code probably since December, basically, which is an extremely large change." — Andrej Karpathy, No Priors podcast, March 2026

That line stuck with me because it names the shift directly. The bottleneck is
not typing anymore. The bottleneck is judgment: knowing what to build, where the
risks are, what the model can quietly break, and how to keep shipping without
letting the stack turn into noise.

I had already built a strong Claude Code workflow around
[superpowers](https://github.com/obra/superpowers). It covers the core
development loop — planning, debugging, TDD, code review, verification. But
the quality layer on top — AI-native security, evals, migrations, observability,
design judgment, release rigor — was missing.

So I built nstack.

nstack is the layer I wanted on top of superpowers: **the definitive AI-native
quality layer** for founders building to scale. It focuses on security,
QA, evals, migrations, observability, design judgment, release rigor, and
premise challenge. It is meant to complement the development workflow, not
compete with it — and to be world-class on the surface it claims.

The design principle that matters most: **depth per skill over breadth of
coverage.** One skill that produces a concrete exploit path with a remediation
step beats three skills that produce pattern-match warnings. Every nstack
skill earns its place by that bar.

**Three setup tiers, honest about each:**
- **Tier 1 — Core (zero setup):** Markdown-only skills for security, review, ship, plan, investigate, retro, and more. `git clone` and they work.
- **Tier 2 — Browser (one-time `./setup`):** Skills that render HTML, take screenshots, or automate a browser — design cluster, QA, benchmark, canary, DevEx audit.
- **Tier 3 — Live observability (per-project integration):** Forward-declared for future agent-loop tracing, prompt replay, live RAG auditing. Each skill publishes its own integration contract.

Superpowers-compatible. Zero overlap with the development loop.

AI lets a small team move at absurd speed. It also lets a small team ship
hallucinated UX, prompt injection holes, invisible regressions, weak product
premises, and brittle agent workflows faster than ever.

Most software tooling still assumes the old failure modes:
- SQL injection
- hardcoded secrets
- broken builds

AI-native projects fail differently:
- prompt injection
- unbounded model spend
- unsafe tool use
- brittle agent workflows
- generic design drift

nstack exists for that gap. It is the quality layer for projects that call
models, orchestrate agents, and handle prompt I/O.

The design cluster is deliberately narrow. It is there for design judgment,
direction-setting, and polish without turning nstack into a heavyweight design
platform.

## Who nstack is for

nstack is for founders building AI-native products who want to ship fast without
cutting corners on security, compliance, or data safety — because they are building
something they intend to scale.

The target is a founder or small team who:
- Is building an AI-native product with the intention to grow and scale it
- Needs to move fast but cannot afford security breaches, prompt injection, or data leaks
- Wants every architectural decision, migration, and release made with the right guardrails in mind from day one — not retrofitted later
- Is using Claude Code as their primary build environment and wants judgment baked into the workflow

nstack does not assume you have a security team, a compliance officer, or a QA department.
It assumes you are building one person's version of all of them, with AI as the multiplier.

nstack is the sharper judgment layer — security-first, enterprise-ready,
AI-native. It fits beside superpowers cleanly and doesn't try to replace it.

## Install

nstack has three setup tiers. You install what you need, when you need it.

Requirements:
- Claude Code (always)
- Git (always)
- Bun v1.0+ — only for Tier 2 browser skills (design cluster, QA, benchmark, canary, DevEx audit)
- Per-project hooks — only for Tier 3 live-observability skills (none shipped yet; forward-declared)

### Tier 1 — Core (zero setup)

```bash
git clone https://github.com/nischal94/nstack.git ~/.claude/skills/nstack
```

Every Tier 1 skill works in the next Claude Code session. No build step. No
binaries. No package manager. Includes: `/cso`, `/review`, `/ship`, `/land`,
`/autoplan`, `/premise`, `/retro`, `/investigate`, `/evals`, `/migrate`,
`/context-audit`, `/checkpoint`, `/health`, `/careful`, `/freeze`,
`/document-release`, `/office-hours`, and (planned for 0.6.0) `/mcp-audit`,
`/compliance-scaffold`, `/plan-devex-review`.

### Tier 2 — Browser (one-time `./setup`)

For skills that render HTML, take screenshots, or automate a browser —
the design cluster, QA, benchmark, canary, DevEx audit:

```bash
cd ~/.claude/skills/nstack && ./setup
```

This downloads Playwright Chromium (~150MB, one-time, ~2 minutes) and
builds the local browser binary. Bun must stay on PATH at runtime.

Tier 2 runtime notes:
- Tier 1 skills keep working even without Bun
- `/design`, `/design-review`, `/qa`, `/benchmark`, `/canary`, `/devex-audit` hard-stop with a setup prompt if the browser binary is missing — never silent fallback
- `/design-consultation` and `/plan-design-review` can proceed without screenshots (soft-skip)

### Tier 3 — Live observability (per-project integration)

Forward-declared tier for future skills that tap into a running application's
telemetry: agent-loop tracing, production prompt replay, live RAG auditing,
cost observability on real traffic. Each Tier 3 skill publishes its own
integration contract (log sink, env hooks, API keys) and is explicitly
opt-in per skill. Nothing ships here yet — nstack ships a Tier 3 skill
only when the capability earns its setup cost concretely.

### Contributing or want full history?

The install above is the simplest path. If you plan to contribute or want full
git history locally, clone the repo wherever you normally keep source checkouts
instead of treating `~/.claude/skills/nstack` as the only copy.

## When to reach for which skill

```
BEFORE YOU BUILD
  Got an idea?                → /premise              (5-10 min gate: should you build it?)
  Need full product diagnostic? → /office-hours       (30-60 min YC-style diagnostic → design doc)
  Need multiple views?        → /council              (adversarial deliberation)
  Have a written plan?        → /autoplan             (review before executing)
  No design system yet?       → /design-consultation  (create DESIGN.md first)
  Plan involves UI?           → /plan-design-review   (critique before writing UI)
  Developer-facing product?   → /plan-devex-review    (DX critique before code)

WHILE YOU BUILD
  Working on risky code?      → /careful              (confirm destructive commands)
  Scope + warn at once?       → /careful here         (warnings + current-dir lock)
  Focused refactor?           → /freeze <path>        (lock edits to one directory)
  Done with the lock?         → /freeze lift          (remove the lock)
  Running a DB migration?     → /migrate              (safety review first)
  Need UI options fast?       → /design sketch N      (explore N variants)

AFTER YOU BUILD
  No UI yet?                  → /design               (lock a first direction)
  UI exists, needs review?    → /design-review        (visual audit + fix loop)
  Changed a prompt?           → /evals                (check quality or regressions)
  Ready to review?            → /review               (review the diff)
  Ready to ship?              → /ship                 (tests → review → version → PR)
  Cutting a release?          → /document-release     (release notes from git history)
  PR open, waiting for CI?    → /land                 (merge → deploy → health check)
  Just deployed?              → /canary               (watch the live app)

WHEN SOMETHING FEELS OFF
  Don't know where to start   → /investigate          (triage the regression)
  Security concerns?          → /cso                  (AI-native security audit)
  MCP servers installed?      → /mcp-audit            (MCP supply chain + injection)
  Compliance looming?         → /compliance-scaffold  (SOC2/GDPR/HIPAA gap map)
  App behaving wrong?         → /qa                   (find and fix bugs)
  Just want a bug report?     → /qa watch             (report-only, no fixes)
  Something seems slower?     → /benchmark            (flag performance regressions)
  DX feels clunky?            → /devex-audit          (live DX audit across 8 passes)
  Claude config drifting?     → /context-audit        (audit CLAUDE.md and rules)

REFLECTION
  End of the week?            → /retro                (what shipped, what drifted)
  Code quality snapshot?      → /health               (composite score, trend)
  Session boundary?           → /checkpoint           (save or resume state)
```

### Design cluster chain

The design cluster is intentionally narrow. It focuses on judgment,
direction-setting, and critique. It does not try to be a full design platform.

Think of the design skills as a sequence, not a menu of unrelated commands.

1. Start with `/design-consultation` when the project has no strong visual system yet.
   Output: `DESIGN.md` with the visual language, taste, constraints, and non-negotiables.
2. Run `/plan-design-review` when you have a UI plan but have not built it yet.
   Output: critique of the plan, missing states, hierarchy issues, and a sharper direction before code is written.
3. Use `/design sketch N` when the direction is still unclear and you need multiple visual options quickly.
   Output: N lightweight HTML variants that help you pick or blend a direction.
4. Use `/design` when you need one approved, coherent direction to move forward with.
   Output: an approved design reference package the coding workflow can build from.
5. Use `/design-review` after the UI exists in the real product.
   Output: a live-product polish pass that catches hierarchy, spacing, typography, and interaction problems.

The important model is:
- `/design-consultation` sets the rules
- `/plan-design-review` critiques the intended solution
- `/design sketch N` explores alternatives if the intended solution is still fuzzy
- `/design` locks a direction
- normal implementation flow builds the product
- `/design-review` audits the built result

There is no separate design-only build subsystem inside nstack. After a direction
is approved, the next step is ordinary implementation work in the real codebase.
The design skills exist to improve what gets built, not to replace the build
workflow itself.

## Skills

26 skills across 7 categories. 3 more planned for 0.6.0 (2 new Tier 1 + 1 port). Skills that share a core job merge into one skill with a mode flag, rather than shipping as two commands.

### Thinking & deciding (4) — Tier 1

| # | Skill | What it does |
|---|-------|-------------|
| 1 | `/premise` | 5-10 minute premise gate. Five structured lenses (status quo, assumption killer, minimum wedge, existing leverage, regret test). Outputs CONFIRMED / NARROWED / CHALLENGED / DEFER. Use before any new feature or project to decide whether to build at all. |
| 2 | `/office-hours` | 30-60 minute YC-style product diagnostic with startup and builder modes, forcing questions, pushback patterns, landscape awareness, cross-model second opinion, alternatives generation. Produces a design doc. Use for deep product thinking before committing to an approach. |
| 3 | `/council` | Multi-agent adversarial deliberation. 11 personas (Socrates, Feynman, Torvalds, etc.), 3-round protocol: independent analysis → cross-examination → synthesis. For architecture choices, strategic pivots, build-vs-buy. |
| 4 | `/autoplan` | Plan review before execution. Scope challenge, architecture review, AI-native checks, test matrix. Outputs BLOCKED / READY with specific gaps. |

### Safety guardrails (2) — Tier 1

| # | Skill | What it does |
|---|-------|-------------|
| 4 | `/careful` | Warns before `rm -rf`, `DROP TABLE`, force-push, `kubectl delete`, and other hard-to-reverse operations. Modes: default (warnings); `/careful here` (warnings + scope lock to current directory). |
| 5 | `/freeze` | Lock all edits to a specific directory for the session. Reads remain unrestricted. Modes: `/freeze <path>` (lock); `/freeze lift` (clear the lock). |

### Building (4) — Tier 1

| # | Skill | What it does |
|---|-------|-------------|
| 6 | `/review` | Inline staff engineer code review of the current diff. AUTO-FIX commits for obvious issues. FLAGS security issues and logic questions for your decision. |
| 7 | `/migrate` | Database migration safety. Classifies risk, checks for missing rollback, warns on lock contention, runs dry-run + backup check + post-migration verification. |
| 8 | `/evals` | LLM output quality testing. Create and run eval suites with string checks and LLM-as-judge scoring. Baseline comparison across prompt or model changes. |
| 9 | `/context-audit` | Claude Code config audit. Finds stale file references, contradictory rules, and bloat across CLAUDE.md, rules files, and memory. |

### Shipping (3) — Tier 1

| # | Skill | What it does |
|---|-------|-------------|
| 10 | `/ship` | Full release checklist: tests → self-review → code review → version bump → CHANGELOG → push → PR. Stops on any failure. |
| 11 | `/land` | Merge, deploy, and verify. Waits for CI → merges → waits for deploy → health checks production. Offers rollback on failure. |
| 12 | `/document-release` | Release notes from git history. Groups commits, determines semver bump, updates CHANGELOG.md. Never tags without confirmation. |

### Quality & monitoring (6) — Tier 1 + Tier 2

| # | Skill | Tier | What it does |
|---|-------|------|-------------|
| 13 | `/cso` | 1 | Security audit: OWASP Top 10, STRIDE, secrets archaeology, CI/CD, dependency supply chain with install-script hunt, LLM/AI security (prompt injection, RAG poisoning, unbounded cost), skill supply chain, agent tool blast-radius. 8/10 confidence gate, zero noise, parallel verification, fingerprint-based trend tracking. |
| 14 | `/qa` | 2 | Browser QA. Modes: default (find bugs + fix with atomic commits + regression tests); `/qa watch` (report-only, no writes, no commits). |
| 15 | `/benchmark` | 2 | Performance regression detection. Baselines TTFB, FCP, LCP, bundle size. Flags regressions with WARN/REGRESSION thresholds. Supports `--trend` for historical drift. |
| 16 | `/canary` | 2 | Post-deploy canary monitoring. Watches the live app after a deploy: console errors, performance regressions, page failures, screenshot comparisons. |
| 17 | `/investigate` | 1 | Bug triage when you don't know where to start. Reconstructs the timeline, diffs the suspect range, builds a hypothesis with confidence rating. |
| 18 | `/retro` | 1 | Weekly retrospective from git history. What shipped, lines added, test health, files touched most, open findings. |

### Session continuity (3) — Tier 1 + Tier 2

| # | Skill | Tier | What it does |
|---|-------|------|-------------|
| 19 | `/checkpoint` | 1 | Save and resume working state. Commits with structured `Context:` + `Next:` lines so `git log` tells you why and where to pick up. Resume mode surfaces last checkpoint at session start. |
| 20 | `/health` | 1 | Code quality dashboard. Auto-detects project tools (tsc, eslint/biome/ruff, test runner, knip, shellcheck), scores each category, composite 0–10 score, tracks trend via `.claude/health-history.jsonl`. |
| 21 | `/devex-audit` | 2 | Live developer experience audit across 8 passes: getting started, API/CLI ergonomics, error messages, docs, upgrade path, dev environment, community, DX measurement. Scores each 0–10 with evidence. Tracks history via `.claude/devex-history.jsonl`. |

### Design (4) — Tier 2

| # | Skill | What it does |
|---|-------|-------------|
| 22 | `/design-consultation` | Create your design system. Researches the competitive space, proposes aesthetic/typography/color/layout/spacing/motion, writes `DESIGN.md` as the project's design source of truth. Run this first. |
| 23 | `/plan-design-review` | Design review before implementation. Generates HTML mockups of planned components, screenshots them, produces an opinionated design plan. Run before writing UI code. |
| 24 | `/design` | Generate a first coherent UI direction. Modes: default (3 variants → pick → packaged as approved reference); `/design sketch N` (N variants → comparison board → no commit). |
| 25 | `/design-review` | Visual design audit + fix loop. Screenshots running pages, analyzes 10 categories (~80 items): typography, color, spacing, accessibility, AI slop detection. Letter grades with evidence. Applies fixes with atomic commits — requires a clean working tree. |

### Planned for 0.6.0

| Skill | Tier | What it will do |
|-------|------|----------------|
| `/mcp-audit` | 1 | MCP server supply chain + permission scope + command-line exploit surface + tool-description injection scan. |
| `/compliance-scaffold` | 1 | SOC2 / GDPR / HIPAA prep gap map for AI-native products at pre-audit stage. Not enforcement — a remediation order. |
| `/plan-devex-review` | 1 | Plan-stage DX review. Explores developer personas, benchmarks against competitors, designs magical moments, traces friction points before scoring. |

## Compatibility

nstack is designed to complement [superpowers](https://github.com/obra/superpowers).
No overlapping skill names. No conflicting workflows. nstack hands off to
superpowers at natural boundaries: debugging a finding, verifying a fix,
reviewing remediation code, or pushing a broader implementation loop forward.

That separation is the point. superpowers covers the development workflow.
nstack sits on top as the quality layer.

## Design principles

- **Three setup tiers** — Tier 1 core skills work on `git clone`; Tier 2 browser skills opt in to Bun + Playwright via `./setup`; Tier 3 live-observability skills publish per-project integration contracts
- **Depth over count** — one excellent skill with concrete exploit paths beats three skills with pattern-match warnings
- **AI-native first** — LLM security is the primary lens, not an afterthought
- **Zero noise** — concrete findings only: exploit paths in security, severity ratings in design, confidence scores in triage. No vague observations.
- **Superpowers-compatible** — complements, never conflicts
- **Scale-ready from day one** — security, compliance, and guardrails built in from the start, not retrofitted later

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Skills are Markdown. No build step to contribute.

## License

MIT
