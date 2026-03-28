# nstack

A Claude Code skill pack for AI-native projects. Zero dependencies. Superpowers-compatible.

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
ETHOS.md                   ← principles injected into skill preambles
ARCHITECTURE.md            ← why nstack is built this way
CONTRIBUTING.md            ← how to contribute
```

## Working in this repo

When editing skills, changes take effect immediately — no build step needed.

## Conventions

- Skill descriptions start with "Use when..." and describe triggering conditions only
- Every security finding needs a concrete exploit scenario
- No dependencies introduced — skills use only Claude's built-in tools
- Hand off to superpowers at natural boundaries (debugging, verification, review)

## Commit style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`

Examples:
- `feat(cso): add CORS misconfiguration check`
- `fix(qa): handle redirect loops in browser flow`
- `docs: update CONTRIBUTING with testing guidance`
