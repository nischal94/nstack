# nstack

The definitive AI-native quality layer for Claude Code. Three setup tiers — core skills work on `git clone`; browser skills opt in via `./setup`; live-observability skills publish per-project integration contracts. Superpowers-compatible.

## Structure

```
# Structure at 0.6.0 — 29 skills total.
# 26 original skills post-merge (4 merges done; /office-hours kept separate from /premise),
# 3 added: /mcp-audit, /compliance-scaffold, /plan-dev-review.

# Core / Tier 1 — zero setup
cso/SKILL.md               ← /cso security audit (absorbs /rag-audit, /cost-audit attack-surface, /agent-safety as phases 7c, 7d, 8b)
review/SKILL.md            ← /review inline staff engineer code review
ship/SKILL.md              ← /ship full release checklist
land/SKILL.md              ← /land merge + deploy + health check
autoplan/SKILL.md          ← /autoplan plan review before execution (depth restoration planned)
premise/SKILL.md           ← /premise challenge whether to build (5-10 min structured gate)
office-hours/SKILL.md      ← /office-hours YC-style product diagnostic (30-60 min, produces design doc)
document-release/SKILL.md  ← /document-release release notes from git history
retro/SKILL.md             ← /retro weekly retrospective (depth restoration planned)
investigate/SKILL.md       ← /investigate bug triage (depth restoration planned)
evals/SKILL.md             ← /evals LLM output quality testing
migrate/SKILL.md           ← /migrate database migration safety
context-audit/SKILL.md     ← /context-audit Claude Code config audit
checkpoint/SKILL.md        ← /checkpoint save & resume working state
health/SKILL.md            ← /health code quality dashboard
careful/SKILL.md           ← /careful destructive command guardrails — modes: default, `here` (scope + warn, absorbs /guard)
freeze/SKILL.md            ← /freeze directory edit lock — modes: default (lock), `lift` (clear, absorbs /unfreeze)
# Planned Tier 1 additions
mcp-audit/SKILL.md         ← /mcp-audit MCP server supply chain + permission scope + tool-description injection scan
compliance-scaffold/SKILL.md ← /compliance-scaffold SOC2/GDPR/HIPAA pre-audit gap map for AI-native products
plan-dev-review/SKILL.md ← /plan-dev-review plan-stage developer-experience review (mirrors /plan-design-review)

# Browser / Tier 2 — requires ./setup (Bun + Playwright)
qa/SKILL.md                ← /qa browser QA — modes: default (find + fix), `watch` (observer, no writes, absorbs /qa-only)
benchmark/SKILL.md         ← /benchmark performance regression detection
canary/SKILL.md            ← /canary post-deploy canary monitoring
dev-audit/SKILL.md       ← /dev-audit live developer experience audit (depth restoration planned)
design/SKILL.md            ← /design UI direction — modes: default (3 variants → package), `sketch N` (N variants → compare, absorbs /design-shotgun)
design-consultation/SKILL.md ← /design-consultation design system from scratch
design-review/SKILL.md     ← /design-review live design visual QA
plan-design-review/SKILL.md ← /plan-design-review pre-build design critique

# Live / Tier 3 — per-project integration (no skills shipped yet; forward-declared)

# Documentation
ETHOS.md                   ← principles (injected into skill preambles)
ARCHITECTURE.md            ← why nstack is built this way + tier + merge rationale
CONTRIBUTING.md            ← how to contribute
docs/audit-2026-04-13.md   ← audit that drove the 0.6.0 reframe
```

## Working in this repo

When editing skills, changes take effect immediately — no build step needed.

## Conventions

- Skill descriptions start with "Use when..." and describe triggering conditions only
- Every security finding needs a concrete exploit scenario
- Core skills avoid mandatory dependencies; design skills opt in to Bun + Playwright
- Hand off to superpowers at natural boundaries (debugging, verification, review)

## Commit style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`

Examples:
- `feat(cso): add CORS misconfiguration check`
- `fix(qa): handle redirect loops in browser flow`
- `docs: update CONTRIBUTING with testing guidance`
