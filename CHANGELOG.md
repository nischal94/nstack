# Changelog

All notable changes to nstack are documented here.

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
- `/context` — Claude Code configuration audit. Reads project CLAUDE.md, global CLAUDE.md, rules files, and memory files. Surfaces stale path references, contradictory rules, missing commands, cross-file conflicts, and bloat. `--fix` mode applies safe changes automatically.
- `/migrate` — Database migration safety. Classifies every operation by risk (LOW/MEDIUM/HIGH/CRITICAL), checks for missing rollback on destructive operations, warns on lock contention for large tables, detects code references to columns being dropped, requires explicit double-confirmation for data loss, and runs post-migration verification (schema, row counts, constraints, indexes). Supports Django, Alembic, Prisma, Flyway, and raw SQL.
- `/land` — CI gate → merge confirmation → squash merge → deploy detection and wait → production health check → rollback offer on failure. Supports Vercel, Fly.io, Railway, Render, Netlify, and generic GitHub Actions deploy workflows.
- `ETHOS.md` — AI-native builder philosophy injected into every skill preamble.
- `ARCHITECTURE.md` — Why nstack is built this way, why Claude-in-Chrome, why superpowers-compatible.
- `CONTRIBUTING.md` — Skill quality bar, testing guidance, PR process.
