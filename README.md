# nstack

> "I don't think I've typed like a line of code probably since December, basically, which is an extremely large change." — Andrej Karpathy, No Priors podcast, March 2026

That line stuck with me because it names the shift directly. The bottleneck is
not typing anymore. The bottleneck is judgment: knowing what to build, where the
risks are, what the model can quietly break, and how to keep shipping without
letting the stack turn into noise.

I had already built a strong Claude Code workflow around
[superpowers](https://github.com/obra/superpowers). Then I found
[gstack](https://github.com/garrytan/gstack), which is excellent. It made the
same thing obvious from another angle: one person with the right AI tooling can
move with the leverage of a much larger team.

But I did not adopt gstack as-is.

For my workflow, there was too much overlap between gstack and superpowers in
the core dev loop. Both touched planning, execution, and general engineering
workflow. I did not want duplicate commands, conflicting habits, or a heavier
stack than I actually needed.

So I built nstack instead.

nstack is the layer I wanted on top of superpowers: a zero-mandatory-setup skill pack
for the gaps neither gstack nor superpowers covered cleanly for AI-native work.
It focuses on security, QA, evals, migrations, observability, design judgment,
release rigor, and premise challenge. It is meant to complement the development
workflow, not compete with it.

29 skills for security auditing, QA, bug triage, design, premise challenges,
release notes, retrospectives, session continuity, code health, and safety guardrails for AI-native projects.
Zero mandatory setup for core skills. Superpowers-compatible.

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

The design cluster is deliberately narrower than gstack's. It is there for
design judgment, direction-setting, and polish without turning nstack into a
heavyweight design platform.

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

If you want a broad workflow framework that behaves like a full virtual engineering team,
reach for gstack. If you want a sharper judgment layer — security-first, enterprise-ready,
AI-native — reach for nstack. If you already run superpowers, nstack is designed to fit
beside it cleanly.

## Quick start

If you only try five commands, try these:

1. `/cso` on any AI-facing repo
2. `/review` on any non-trivial diff
3. `/qa` on a running app
4. `/design-consultation` before building a new UI-heavy surface
5. `/plan-design-review` before writing UI code

That sequence shows the core shape of nstack quickly:
- security before trust is assumed
- review before changes are merged
- QA before “works on my machine” becomes a belief
- design direction before UI drift starts

By use case:
- Starting a new AI product: `/premise`, `/office-hours`, `/design-consultation`, `/autoplan`
- Building a UI-heavy feature: `/plan-design-review`, `/design-shotgun`, `/design`, `/design-review`
- Doing a security and quality pass: `/cso`, `/review`, `/qa`, `/evals`
- Getting ready to ship: `/review`, `/qa` or `/qa-only`, `/ship`, `/canary`

## Install

Requirements:
- Claude Code
- Git
- Bun v1.0+ only if you want the design skills

### Step 1: Install nstack

```bash
git clone https://github.com/nischal94/nstack.git ~/.claude/skills/nstack
```

Core skills work immediately after clone. No build step. No binaries. No package
manager required for the core Markdown skills.

### Step 2: Optional — enable design skills

Design skills (`/design`, `/design-review`, `/design-shotgun`, `/design-consultation`, `/plan-design-review`) use a Bun-powered Playwright CLI for fast, token-free screenshot rendering. To enable:

```bash
cd ~/.claude/skills/nstack && ./setup
```

This downloads Playwright Chromium (~150MB, one-time) and builds the local
browser binary used by the design cluster.

Design runtime notes:
- Bun is required at both install time and runtime
- core skills still work without Bun
- `/design` and `/design-review` hard-stop if the browser binary is missing
- `/design-consultation`, `/design-shotgun`, and `/plan-design-review` can proceed without screenshots

### Contributing or want full history?

The install above is the simplest path. If you plan to contribute or want full
git history locally, clone the repo wherever you normally keep source checkouts
instead of treating `~/.claude/skills/nstack` as the only copy.

## When to reach for which skill

```
BEFORE YOU BUILD
  Got an idea?              → /premise              (challenge whether to build it)
  Need multiple views?      → /council              (adversarial deliberation)
  Big product decision?     → /office-hours         (YC-style validation)
  Have a written plan?      → /autoplan             (review before executing)
  No design system yet?     → /design-consultation  (create DESIGN.md first)
  Plan involves UI?         → /plan-design-review   (critique before writing UI)

WHILE YOU BUILD
  Working on risky code?    → /careful         (confirm destructive commands)
  Focused refactor?         → /freeze          (lock edits to one directory)
  Done with the lock?       → /unfreeze        (remove the directory lock)
  Both at once?             → /guard           (careful + freeze)
  Running a DB migration?   → /migrate         (safety review first)
  Need UI options fast?     → /design-shotgun  (explore directions quickly)

AFTER YOU BUILD
  No UI yet?                → /design              (lock a first direction)
  UI exists, needs review?  → /design-review       (visual audit + fix loop)
  Changed a prompt?         → /evals               (check quality or regressions)
  Ready to review?          → /review              (review the diff)
  Ready to ship?            → /ship                (tests → review → version → PR)
  Cutting a release?        → /document-release    (release notes from git history)
  PR open, waiting for CI?  → /land                (merge → deploy → health check)
  Just deployed?            → /canary              (watch the live app)

WHEN SOMETHING FEELS OFF
  Don't know where to start → /investigate     (triage the regression)
  Security concerns?        → /cso             (AI-native security audit)
  App behaving wrong?       → /qa              (browser QA, find and fix bugs)
  Just want a QA report?    → /qa-only         (report-only, no fixes)
  Something seems slower?   → /benchmark       (flag performance regressions)
  Claude config drifting?   → /context-audit   (audit CLAUDE.md and rules)

REFLECTION
  End of the week?          → /retro           (what shipped, what drifted, what to fix)
```

### Design cluster chain

The design cluster is intentionally lighter than gstack's design subsystem. It
focuses on judgment, direction-setting, and critique. It does not try to be a
full design platform.

Think of the design skills as a sequence, not a menu of unrelated commands.

1. Start with `/design-consultation` when the project has no strong visual system yet.
   Output: `DESIGN.md` with the visual language, taste, constraints, and non-negotiables.
2. Run `/plan-design-review` when you have a UI plan but have not built it yet.
   Output: critique of the plan, missing states, hierarchy issues, and a sharper direction before code is written.
3. Use `/design-shotgun` when the direction is still unclear and you need multiple visual options quickly.
   Output: lightweight HTML variants that help you pick or blend a direction.
4. Use `/design` when you need one approved, coherent direction to move forward with.
   Output: an approved design reference package the coding workflow can build from.
5. Use `/design-review` after the UI exists in the real product.
   Output: a live-product polish pass that catches hierarchy, spacing, typography, and interaction problems.

The important model is:
- `/design-consultation` sets the rules
- `/plan-design-review` critiques the intended solution
- `/design-shotgun` explores alternatives if the intended solution is still fuzzy
- `/design` locks a direction
- normal implementation flow builds the product
- `/design-review` audits the built result

There is no separate design-only build subsystem inside nstack. After a direction
is approved, the next step is ordinary implementation work in the real codebase.
The design skills exist to improve what gets built, not to replace the build
workflow itself.

## Skills

29 skills across 7 categories.

### Thinking & deciding (4)

| # | Skill | What it does |
|---|-------|-------------|
| 1 | `/premise` | Premise challenge before building. Five structured challenges: status quo, assumption killer, minimum wedge, existing leverage, regret test. Outputs CONFIRMED / NARROWED / CHALLENGED / DEFER. |
| 2 | `/office-hours` | YC-style product validation. Same 5 lenses as `/premise` but conversational — for ideas still being shaped. |
| 3 | `/council` | Multi-agent adversarial deliberation. 11 personas (Socrates, Feynman, Torvalds, etc.), 3-round protocol: independent analysis → cross-examination → synthesis. For architecture choices, strategic pivots, build-vs-buy. |
| 4 | `/autoplan` | Plan review before execution. Scope challenge, architecture review, AI-native checks, test matrix. Outputs BLOCKED / READY with specific gaps. |

### Safety guardrails (4)

| # | Skill | What it does |
|---|-------|-------------|
| 5 | `/careful` | Warns before `rm -rf`, `DROP TABLE`, force-push, `kubectl delete`, and other hard-to-reverse operations. |
| 6 | `/freeze [path]` | Lock all edits to a specific directory for the session. Reads remain unrestricted. |
| 7 | `/guard [path]` | Full safety mode: `/careful` + `/freeze` combined. For high-stakes sessions on production code. |
| 8 | `/unfreeze` | Remove a `/freeze` or `/guard` directory lock. |

### Building (4)

| # | Skill | What it does |
|---|-------|-------------|
| 9 | `/review` | Inline staff engineer code review of the current diff. AUTO-FIX commits for obvious issues. FLAGS security issues and logic questions for your decision. |
| 10 | `/migrate` | Database migration safety. Classifies risk, checks for missing rollback, warns on lock contention, runs dry-run + backup check + post-migration verification. |
| 11 | `/evals` | LLM output quality testing. Create and run eval suites with string checks and LLM-as-judge scoring. Baseline comparison across prompt or model changes. |
| 12 | `/context-audit` | Claude Code config audit. Finds stale file references, contradictory rules, and bloat across CLAUDE.md, rules files, and memory. |

### Shipping (3)

| # | Skill | What it does |
|---|-------|-------------|
| 13 | `/ship` | Full release checklist: tests → self-review → code review → version bump → CHANGELOG → push → PR. Stops on any failure. |
| 14 | `/land` | Merge, deploy, and verify. Waits for CI → merges → waits for deploy → health checks production. Offers rollback on failure. |
| 15 | `/document-release` | Release notes from git history. Groups commits, determines semver bump, updates CHANGELOG.md. Never tags without confirmation. |

### Quality & monitoring (7)

| # | Skill | What it does |
|---|-------|-------------|
| 16 | `/cso` | 14-phase security audit. OWASP Top 10, STRIDE, secrets archaeology, CI/CD pipeline security, LLM/AI security. 8/10 confidence gate — zero noise by default. |
| 17 | `/qa` | Browser QA via Claude-in-Chrome. Find bugs, fix with atomic commits, generate regression tests, re-verify. |
| 18 | `/qa-only` | Report-only browser QA. Same as `/qa` but never fixes — produces a health score and repro steps only. |
| 19 | `/benchmark` | Performance regression detection. Baselines TTFB, FCP, LCP, bundle size. Flags regressions with WARN/REGRESSION thresholds. Supports `--trend` for historical drift. |
| 20 | `/canary` | Post-deploy canary monitoring. Watches the live app after a deploy: console errors, performance regressions, page failures, screenshot comparisons. |
| 21 | `/investigate` | Bug triage when you don't know where to start. Reconstructs the timeline, diffs the suspect range, builds a hypothesis with confidence rating. |
| 22 | `/retro` | Weekly retrospective from git history. What shipped, lines added, test health, files touched most, open findings. |

### Session continuity (2)

| # | Skill | What it does |
|---|-------|-------------|
| 28 | `/checkpoint` | Save and resume working state. Commits with structured `Context:` + `Next:` lines so `git log` tells you why and where to pick up. Resume mode surfaces last checkpoint at session start. |
| 29 | `/health` | Code quality dashboard. Auto-detects project tools (tsc, eslint/biome/ruff, test runner, knip, shellcheck), scores each category, produces a composite 0-10 score, and tracks trend across runs via `.claude/health-history.jsonl`. |

### Design (5) ★ requires `./setup`

| # | Skill | What it does |
|---|-------|-------------|
| 23 | `/design-consultation` | Create your design system. Researches the competitive space, proposes aesthetic/typography/color/layout/spacing/motion, writes `DESIGN.md` as the project's design source of truth. Run this first. |
| 24 | `/plan-design-review` | Design review before implementation. Generates HTML mockups of planned components, screenshots them, produces an opinionated design plan. Run before writing UI code. |
| 25 | `/design` | Generate a first coherent direction. Produces an approved design reference package for the normal coding workflow. |
| 26 | `/design-shotgun` | Explore directions fast. Generates lightweight HTML variants so you can pick or blend a direction before building. |
| 27 | `/design-review` | Visual design audit + fix loop. Screenshots running pages, analyzes 10 categories (~80 items): typography, color, spacing, accessibility, AI slop detection. Letter grades with evidence. Applies fixes with atomic commits — requires a clean working tree. |

## Why not just use gstack?

[gstack](https://github.com/garrytan/gstack) is excellent. Garry saw the same
macro shift I did: one builder can now ship with the leverage of a much larger
team. But I built nstack because I wanted different tradeoffs.

The short version:
- I was already using [superpowers](https://github.com/obra/superpowers), and gstack overlapped too much with it in the core dev loop.
- I wanted core skills to work immediately after `git clone`, without Bun, Playwright, or a browser daemon.
- I wanted stronger emphasis on AI-native security, prompt quality, migration safety, observability, and product judgment.
- I wanted clean handoff points into superpowers instead of competing abstractions.

nstack is not "gstack, smaller." It is a more opinionated layer for a different
workflow shape.

| | nstack | gstack |
|---|---|---|
| Install | `git clone` (core works instantly) | `git clone + ./setup` (requires Bun, ~2 min) |
| Core skills | Zero mandatory setup | Bun + Playwright required |
| Design skills | Optional `./setup` (same Bun + Playwright) | Required for all skills |
| LLM/AI security | First-class: prompt injection, cost attacks, RAG poisoning, tool validation | Covered, but not the primary lens |
| Skill count | 27 | 31 |
| superpowers | Designed to complement | Independent workflow system |
| Multi-agent | Designed for Claude Code workflows | Claude Code, Codex, Gemini CLI, Factory Droid |
| Team features | Scale-ready defaults, founder-first | Team-aware (teammate install, shared skills) |

**Use nstack if:** You want a lighter quality layer for AI-native work, especially if you already use superpowers or want core skills that work with zero mandatory setup.

**Use gstack if:** You want a broader workflow framework with built-in team and multi-agent features.

**Use both if:** You want gstack's broader workflow tooling and nstack's AI-native quality layer. The skill names do not collide.

## Compatibility

nstack is designed to complement [superpowers](https://github.com/obra/superpowers).
No overlapping skill names. No conflicting workflows. nstack hands off to
superpowers at natural boundaries: debugging a finding, verifying a fix,
reviewing remediation code, or pushing a broader implementation loop forward.

That separation is the point. superpowers covers the development workflow.
nstack sits on top as the quality layer.

## Design principles

- **Zero mandatory setup** — clone and core Markdown skills work immediately; design skills opt in to Bun + Playwright via `./setup`
- **AI-native first** — LLM security is not an afterthought
- **Zero noise** — concrete findings only: exploit paths in security, severity ratings in design, confidence scores in triage. No vague observations.
- **Superpowers-compatible** — complements, never conflicts
- **Scale-ready from day one** — security, compliance, and guardrails built in from the start, not retrofitted later

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Skills are Markdown. No build step to contribute.

## License

MIT
