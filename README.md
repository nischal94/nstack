# nstack

> 27 skills for security auditing, QA, bug triage, design, premise challenges, release notes, retrospectives, and safety guardrails for AI-native projects.
> Zero mandatory setup for core skills. Superpowers-compatible.

Most security tools were built before LLMs existed. They find SQL injection.
They don't find prompt injection. They find hardcoded secrets. They don't find
LLM output rendered as raw HTML. They find CVEs. They don't find unbounded API
calls draining your budget in minutes.

nstack is the quality layer for projects that call models, orchestrate agents,
and handle prompt I/O.

## When to reach for which skill

```
BEFORE YOU BUILD
  Got an idea?              → /premise              (challenge whether to build it at all)
  Need multiple views?      → /council              (adversarial deliberation before deciding)
  Big product decision?     → /office-hours         (YC-style validation)
  Have a written plan?      → /autoplan             (review the plan before executing)
  No design system yet?     → /design-consultation  (create DESIGN.md before touching UI)
  Plan involves UI?         → /plan-design-review   (design review before a line of code)

WHILE YOU BUILD
  Working on risky code?    → /careful         (confirm before destructive commands)
  Focused refactor?         → /freeze          (lock edits to one directory)
  Done with the lock?       → /unfreeze        (remove the directory lock)
  Both at once?             → /guard           (careful + freeze combined)
  Running a DB migration?   → /migrate         (safety review before applying)
  Need UI options fast?     → /design-shotgun  (parallel variants, pick the best)

AFTER YOU BUILD
  No UI yet?                → /design              (generate UI from scratch)
  UI exists, needs review?  → /design-review       (visual audit + fix loop; mutates repo)
  Changed a prompt?         → /evals               (did quality improve or regress?)
  Ready to review?          → /review              (inline staff engineer review of your diff)
  Ready to ship?            → /ship                (tests → review → version → changelog → PR)
  Cutting a release?        → /document-release    (release notes from git history)
  PR open, waiting for CI?  → /land                (merge → deploy → health check)
  Just deployed?            → /canary              (watch the live app after a deploy)
  Performance change?       → /benchmark           (before/after metrics, flag regressions)

WHEN SOMETHING BREAKS
  Don't know where to start → /investigate     (triage the regression, find the suspect)
  Security concerns?        → /cso             (full AI-native security audit)
  App behaving wrong?       → /qa              (browser QA, find bugs, fix and re-verify)
  Just want a QA report?    → /qa-only         (report-only, no fixes)
  Claude config drifting?   → /context         (audit CLAUDE.md, rules, memory for staleness)

REFLECTION
  End of the week?          → /retro           (what shipped, what drifted, what to fix)
```

## Install

```bash
git clone https://github.com/nischal94/nstack.git ~/.claude/skills/nstack
```

Core skills work immediately — no build step, no binaries.

### Optional: design skills

Design skills (`/design`, `/design-review`, `/design-shotgun`, `/design-consultation`, `/plan-design-review`) use a Bun-powered Playwright CLI for fast, token-free screenshot rendering. To enable:

```bash
cd ~/.claude/skills/nstack && ./setup
```

Requires Bun at both install time and runtime (the CLI spawns a Bun server process). Downloads Playwright Chromium (~150MB, one-time). Design skills hard-stop with an install prompt if the binary is missing — `/design-consultation`, `/design-shotgun`, and `/plan-design-review` soft-skip screenshots instead.

## Skills

27 skills across 6 categories.

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
| 12 | `/context` | Claude Code config audit. Finds stale file references, contradictory rules, and bloat across CLAUDE.md, rules files, and memory. |

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

### Design (5) ★ requires `./setup`

| # | Skill | What it does |
|---|-------|-------------|
| 23 | `/design-consultation` | Create your design system. Researches the competitive space, proposes aesthetic/typography/color/layout/spacing/motion, writes `DESIGN.md` as the project's design source of truth. Run this first. |
| 24 | `/plan-design-review` | Design review before implementation. Generates HTML mockups of planned components, screenshots them, produces an opinionated design plan. Run before writing UI code. |
| 25 | `/design` | Generate UI from scratch. 3 HTML variants in parallel (minimal/bold/data-dense), screenshots each, applies the chosen design to the actual tech stack. |
| 26 | `/design-shotgun` | Explore directions fast. Generates 4+ variants in parallel, presents a comparison board for selection. |
| 27 | `/design-review` | Visual design audit + fix loop. Screenshots running pages, analyzes 10 categories (~80 items): typography, color, spacing, accessibility, AI slop detection. Letter grades with evidence. Applies fixes with atomic commits — requires a clean working tree. |

## Usage

Just type the skill. No arguments needed to get started.

```
# Thinking & deciding
/premise "add multi-tenant support"    challenge whether to build it
/office-hours                          YC-style product validation
/council "should we go GraphQL-only?"  multi-perspective deliberation
/autoplan                              review the plan before executing

# Safety guardrails
/careful                               confirm before destructive commands
/freeze src/payments/                  lock edits to one directory
/guard src/payments/                   careful + freeze combined
/unfreeze                              remove the lock

# Building
/review                                staff engineer review of your diff
/migrate                               safety review before applying a migration
/evals                                 run LLM output quality tests
/context                               audit your Claude Code config

# Shipping
/ship                                  tests → review → version → changelog → PR
/land                                  merge → deploy → health check
/document-release                      release notes from git history

# Quality & monitoring
/cso                                   audit for security vulnerabilities
/qa https://localhost:3000             browser QA — find bugs, fix, re-verify
/qa-only https://localhost:3000        QA report only, no fixes
/benchmark                             performance regression check
/canary                                monitor the live app after a deploy
/investigate "costs spiked"            triage a regression
/retro                                 weekly retrospective from git history

# Design  ★ requires ./setup
/design-consultation                   create your design system (start here)
/plan-design-review                    design review before writing UI code
/design                                generate UI from scratch
/design-shotgun                        explore multiple design directions fast
/design-review https://localhost:3000  visual audit + fix loop (commits changes)
```

## Why not just use gstack?

[gstack](https://github.com/garrytan/gstack) is excellent. 31 skills, a compiled browser daemon, team-oriented workflow, multi-agent support (Codex, Gemini CLI, Factory Droid). If you want the full AI engineering team simulator, use gstack.

nstack makes a different set of tradeoffs:

| | nstack | gstack |
|---|---|---|
| Install | `git clone` (core works instantly) | `git clone + ./setup` (requires Bun, ~2 min) |
| Core skills | Zero mandatory setup | Bun + Playwright required |
| Design skills | Optional `./setup` (same Bun + Playwright) | Required for all skills |
| LLM/AI security | First-class — prompt injection, cost attacks, RAG poisoning, tool call validation | Covered but not the primary lens |
| Skill count | 27 | 31 |
| superpowers | Designed to complement | Separate system |
| Multi-agent | Claude Code only | Claude Code, Codex, Gemini CLI, Factory Droid |
| Team features | Solo-builder defaults | Team-aware (teammate install, shared skills) |

**Use nstack if:** You're building AI-native projects and want LLM security as a first-class concern. Or you want zero-setup core skills that work the moment you clone.

**Use gstack if:** You want the full sprint workflow, multi-agent support, or team-oriented features.

**Use both if:** They don't conflict — no overlapping skill names. nstack's AI-native security coverage complements gstack's broader workflow tooling.

## Compatibility

nstack is designed to complement [superpowers](https://github.com/obra/superpowers).
No overlapping skill names. No conflicting workflows. nstack hands off to superpowers
at natural boundaries — debugging a finding, verifying a fix, reviewing remediation code.

## Design principles

- **Zero mandatory dependencies** — clone and core skills work; design skills opt in to Playwright
- **AI-native first** — LLM security is not an afterthought
- **Zero noise** — concrete findings only: exploit paths in security, severity ratings in design, confidence scores in triage. No vague observations.
- **Superpowers-compatible** — complements, never conflicts
- **Solo-builder defaults** — no team assumptions baked in

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Skills are Markdown. No build step to contribute.

## License

MIT
