# nstack

A Claude Code skill pack for AI-native projects. Zero mandatory setup for core skills. Superpowers-compatible.

## Structure

```
cso/SKILL.md               ← /cso security audit skill
qa/SKILL.md                ← /qa browser QA skill
retro/SKILL.md             ← /retro retrospective skill
investigate/SKILL.md       ← /investigate bug triage skill
document-release/SKILL.md  ← /document-release release notes skill
ship/SKILL.md              ← /ship full release checklist skill
careful/SKILL.md           ← /careful destructive command guardrails
freeze/SKILL.md            ← /freeze directory edit lock
guard/SKILL.md             ← /guard careful + freeze combined
unfreeze/SKILL.md          ← /unfreeze remove directory lock
premise/SKILL.md           ← /premise challenge whether to build something
land/SKILL.md              ← /land merge + deploy + health check
review/SKILL.md            ← /review inline staff engineer code review
autoplan/SKILL.md          ← /autoplan plan review before execution
evals/SKILL.md             ← /evals LLM output quality testing
context-audit/SKILL.md     ← /context-audit Claude Code configuration audit
checkpoint/SKILL.md        ← /checkpoint save & resume working state across sessions
health/SKILL.md            ← /health code quality dashboard with composite score and trend tracking
devex-audit/SKILL.md      ← /devex-audit live developer experience audit across 8 passes
migrate/SKILL.md           ← /migrate database migration safety
office-hours/SKILL.md      ← /office-hours YC-style product validation
qa-only/SKILL.md           ← /qa-only report-only browser QA
benchmark/SKILL.md         ← /benchmark performance regression detection
canary/SKILL.md            ← /canary post-deploy canary monitoring
design/SKILL.md            ← /design generate a first coherent UI direction
design-consultation/SKILL.md ← /design-consultation interactive design system creation
design-review/SKILL.md     ← /design-review designer's eye visual QA
design-shotgun/SKILL.md    ← /design-shotgun fast design direction exploration
plan-design-review/SKILL.md ← /plan-design-review pre-build design critique
ETHOS.md                   ← principles injected into skill preambles
ARCHITECTURE.md            ← why nstack is built this way
CONTRIBUTING.md            ← how to contribute
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
