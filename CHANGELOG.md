# Changelog

All notable changes to nstack are documented here.

---

## [0.6.0] — Unreleased (planning)

Reframe release: nstack is the definitive AI-native quality layer for founders building at scale. Depth and judgment per skill over breadth of coverage.

### Planned

**Three setup tiers (formalized in ETHOS.md + ARCHITECTURE.md)**
- **Tier 1 — Core (zero setup):** Markdown-only skills. `git clone` and they work.
- **Tier 2 — Browser (one-time `./setup`):** Bun + Playwright. Design cluster, QA, benchmark, canary, DevEx audit.
- **Tier 3 — Live observability (per-project integration):** Forward-declared for future agent-loop tracing, prompt replay, live RAG auditing. Each skill publishes its own integration contract.

**Skill consolidation (30 → 25)** — functional duplicates merged into richer parent skills with creative mode names:
- `/unfreeze` → `/freeze lift`
- `/qa-only` → `/qa watch`
- `/office-hours` → `/premise office`
- `/design-shotgun` → `/design sketch N`
- `/guard` → `/careful here`

**Depth restoration (5 skills)** — content-diff against gstack source surfaced substantive signal loss in the initial port. Planned restorations:
- `/cso` — Phase 3 install-script hunt (supply-chain RCE), Phase 7 RAG poisoning + cost-amplification loop patterns with concrete regex examples, Phase 8 FP exceptions, Phase 8a Snyk ToxicSkills threat context, Phase 12 Agent-tool parallel verification, Phase 14 JSON schema with fingerprints. New Phase 7c (RAG), 7d (cost attack-surface), 8b (agent tool blast-radius) absorb what would have been standalone `/rag-audit`, `/cost-audit`, `/agent-safety` skills.
- `/autoplan` — dual-voice architecture (Claude + Codex consensus tables), Phase 0 scope detection, decision classification (mechanical / taste / user-challenge), 6 decision principles with tiebreakers, sequential phase execution, audit trail logging, pre-gate verification, final approval gate with user-challenge handling.
- `/investigate` — Phase 2 bug pattern catalog (race conditions, nil propagation, cache staleness, config drift), structured DEBUG REPORT format, "3+ failed attempts → stop" thrashing guard, regression test minimal-diff discipline.
- `/devex-audit` — Seven DX Characteristics calibration framework, Hall of Fame reference for scoring, Boomerang Baseline (plan vs reality delta), Completion Status Protocol.
- `/retro` — Backlog Health (TODOS.md deltas), Streak tracking, Week-over-week trend buckets, AI-assisted-commit detection via `Co-Authored-By: noreply@anthropic.com`.

**New Tier 1 skills**
- `/mcp-audit` — MCP server supply chain + permission scope + command-line exploit surface + tool-description injection scan. Dry-run on the nstack author's machine surfaced one real MEDIUM finding (unpinned global npm package on a reputable publisher). Zero setup.
- `/prompt-author` — Opinionated prompt authoring discipline: system/user boundary, injection-proof structure, cache-friendly layout, testability checklist. Zero setup.
- `/compliance-scaffold` — SOC2 / GDPR / HIPAA prep gap map for AI-native products at pre-audit stage. Not enforcement — a remediation order for founders building to scale. Zero setup.

**Port from gstack**
- `/plan-devex-review` — plan-stage DX review. Mirrors the `/plan-design-review` ↔ `/design-review` pattern. Explores developer personas, benchmarks against competitors, designs magical moments, and traces friction points before scoring. Zero setup.

### Added (documentation — this session)
- ETHOS.md — new principle #6 "Depth over count"; principle #3 refined into explicit three setup tiers.
- ARCHITECTURE.md — three-tier formalization; skill consolidation rationale; `/cso` phase absorption documentation.
- CLAUDE.md — target 0.6.0 structure list with tier labels and merge notes.
- docs/audit-2026-04-13.md — full three-way audit (nstack ↔ gstack ↔ superpowers) and five-skill depth-diff findings that drove the reframe.

---

## [0.5.0] — 2026-04-04

### Added
- `/devex-audit` — Live developer experience audit across 8 passes (getting started, API/CLI ergonomics, error messages, docs, upgrade path, dev environment, community, DX measurement). Uses Playwright browse binary for screenshots. Scores each pass 0-10 with evidence labels (TESTED/INFERRED/PARTIAL). Tracks history via `.claude/devex-history.jsonl`. Gracefully degrades to file-only mode without browser binary.

---

## [0.4.0] — 2026-04-04

### Added
- `/health` — Code quality dashboard. Auto-detects project tools (tsc, eslint/biome/ruff, pytest/bun test/cargo test, knip, shellcheck), scores each category 0-10 with weighted composite score, and tracks trend across runs via `.claude/health-history.jsonl`. No binary dependencies — wraps whatever tools the project already has.

---

## [0.3.0] — 2026-04-04

### Added
- `/checkpoint` — Save and resume working state across sessions. Save mode commits with structured `Context:` + `Next:` lines so git history tells you why changes were made and where to pick up. Resume mode reads the last checkpoint and surfaces state at session start. Zero dependencies.

---

## [0.2.0] — 2026-04-01

### Added
- `/office-hours` — YC-style product validation. Five structured lenses (status quo, assumption killer, minimum wedge, existing leverage, regret test). Outputs CONFIRMED / NARROWED / CHALLENGED / DEFER verdict.
- `/qa-only` — Report-only browser QA. Tests web apps like a real user, documents issues with screenshots and repro steps, produces a health score. Never fixes anything — use `/qa` for the fix loop.
- `/benchmark` — Performance regression detection. Establishes baselines, compares before/after metrics (TTFB, FCP, LCP, bundle size), flags regressions with WARN/REGRESSION thresholds. Supports `--trend` for historical drift.
- `/canary` — Post-deploy canary monitoring. Watches the live app after a deploy: console errors, performance regressions, page failures. Takes periodic screenshots and compares against pre-deploy baselines.
- `/design` — Generate UI from scratch. Reads the codebase, generates 3 HTML design variants in parallel (minimal/bold/data-dense), screenshots each, picks the best with user input, applies to the actual tech stack.
- `/design-consultation` — Interactive design system creation. Researches the competitive space, proposes aesthetic/typography/color/layout/spacing/motion, generates visual previews, writes `DESIGN.md` as the project's design source of truth.
- `/design-review` — Visual design audit. Screenshots running pages, analyzes typography, color, spacing, accessibility contrast, and UX patterns across 10 categories (~80 items). Produces a structured critique with letter grades and evidence.
- `/design-shotgun` — Design variant exploration. Generates 4+ design variants in parallel using Agent dispatch, screenshots each, presents a comparison board for selection.
- `/plan-design-review` — Pre-implementation design planning. Reviews planned components, generates HTML mockups, screenshots them, and produces an opinionated design plan before a line of code is written.

### Changed
- **Removed MCP browser fallback from all 5 design skills.** MCP screenshots return base64 image data inline — hundreds of KB of tokens per screenshot, prohibitive at design-workflow volumes (4–20 screenshots per run). Design skills now use the Playwright binary exclusively. `/design` and `/design-review` hard-stop with an install prompt if the binary is missing; `/design-consultation`, `/design-shotgun`, and `/plan-design-review` soft-skip screenshots and proceed.
- **Invariant cleanup pass across all 5 design skills.** Fixed shell-state loss across Bash calls (variables now persisted to file where needed), unresolved placeholders, binary/MCP path mismatches, and impossible tool instructions. See commit history for per-skill details.
- **`/cso`** — Added Phase 8a supply chain analysis and trend tracking for emerging threat categories.
- **`/canary`** — Added `text_snapshot` field to baseline schema for content regression detection.

### Fixed
- `design-review` Phase 8d: added `$B snapshot -i` before `$B snapshot -D` so diffs baseline the fixed page, not stale pre-fix state
- `design-shotgun`: `_DESIGN_DIR` and `_PORT` now persisted to file; `_IMAGES` construction and `$D compare` merged into a single Bash block
- `design-consultation` Phase 2.5: subagent prompt now requires explicit product context substitution before dispatch
- `plan-design-review`: approval JSON Write path changed from unexpanded `$TMPDIR` to `<resolved-TMPDIR>`

---

## [0.1.0] — 2026-03-27

### Added
- `/cso` — 14-phase security audit for AI-native projects. OWASP Top 10, STRIDE threat modeling, secrets archaeology, CI/CD pipeline security, LLM/AI security (prompt injection, unsanitized output, tool call validation, cost attacks), supply chain analysis. 8/10 confidence gate, zero noise default.
- `/qa` — Browser QA using Claude-in-Chrome MCP. Find bugs, fix with atomic commits, generate regression tests, re-verify. Zero dependencies.
- `/retro` — Weekly retrospective from git history and Claude Code logs. Lines added/removed, commits, test health trend, files touched most, what shipped summary.
- `/investigate` — Bug triage when you don't know where to start. Timeline reconstruction, suspect diff analysis, AI-native regression patterns (cost spikes, output degradation, prompt changes), structured hypothesis report with confidence rating. Hands off to superpowers:systematic-debugging.
- `/document-release` — Release notes from git history. Consolidates commits into user-facing entries, determines semver bump from Conventional Commits, updates CHANGELOG.md. Never tags or pushes without confirmation.
- `/ship` — Full release checklist in one command: tests → self-review → code review → version bump → CHANGELOG → push → PR. Stops on any failure. Delegates review to superpowers:requesting-code-review.
- `/careful` — Destructive command guardrails. Intercepts `rm -rf`, `DROP TABLE`, force-push, `kubectl delete`, `terraform destroy`, and other hard-to-reverse operations before they run. Requires explicit confirmation.
- `/freeze` — Directory edit lock. Restricts all writes and edits to a specified path for the session. Reads remain unrestricted. Blocks silently on violation.
- `/guard` — Full safety mode: `/careful` + `/freeze` combined. For high-stakes sessions on production code or shared infrastructure.
- `/unfreeze` — Remove the active directory lock from `/freeze` or `/guard`. Careful mode remains active until explicitly disabled.
- `/premise` — Premise challenge before building. Five structured challenges (status quo, assumption killer, minimum wedge, existing leverage, regret test) with one question at a time. Outputs a CONFIRMED / NARROWED / CHALLENGED / DEFER verdict with a recommended next step.
- `/land` — Merge, deploy, and verify in one command.
- `/review` — Inline staff engineer code review of the current diff. Classifies findings as AUTO-FIX (applied immediately with atomic commits) or FLAG (presented for user decision). Never auto-fixes security issues. Cites file and line for every finding.
- `/autoplan` — Plan review pipeline before execution. Three passes: scope challenge (minimum change set, 8-file smell, existing leverage), architecture review (data flow, dependency direction, error paths, AI-native checks), and test matrix (traces every behavior to a test, adds missing tests to the plan). Outputs BLOCKED / READY verdict.
- **fix(/investigate):** Added 3-strike rule — after 3 failed hypotheses, stops and surfaces options (instrumentation, bisect, escalate, scope expansion) rather than thrashing. Added scope lock step that declares the investigation boundary before forming any hypothesis.
- **fix(/ship):** Added base-branch merge before running tests (Step 2). Tests now run on the merged state, not the branch in isolation. Added test failure triage to distinguish new failures (blocking) from pre-existing failures (flagged, non-blocking).
- `/evals` — LLM output quality testing. Create and run structured eval suites with typed checks (contains, not_contains, max_length, format, json_valid, regex, llm_judge). Baseline tracking across runs. `--compare` mode diffs two configurations case-by-case.
- `/context-audit` — Claude Code configuration audit. Reads project CLAUDE.md, global CLAUDE.md, rules files, and memory files. Surfaces stale path references, contradictory rules, missing commands, cross-file conflicts, and bloat. `--fix` mode applies safe changes automatically.
- `/migrate` — Database migration safety. Classifies every operation by risk (LOW/MEDIUM/HIGH/CRITICAL), checks for missing rollback on destructive operations, warns on lock contention for large tables, detects code references to columns being dropped, requires explicit double-confirmation for data loss, and runs post-migration verification (schema, row counts, constraints, indexes). Supports Django, Alembic, Prisma, Flyway, and raw SQL.
- `/land` — CI gate → merge confirmation → squash merge → deploy detection and wait → production health check → rollback offer on failure. Supports Vercel, Fly.io, Railway, Render, Netlify, and generic GitHub Actions deploy workflows.
- `ETHOS.md` — AI-native builder philosophy injected into every skill preamble.
- `ARCHITECTURE.md` — Why nstack is built this way, why Claude-in-Chrome, why superpowers-compatible.
- `CONTRIBUTING.md` — Skill quality bar, testing guidance, PR process.
