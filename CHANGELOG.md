# Changelog

All notable changes to nstack are documented here.

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
- `/land` — Merge, deploy, and verify in one command. CI gate → merge confirmation → squash merge → deploy detection and wait → production health check → rollback offer on failure. Supports Vercel, Fly.io, Railway, Render, Netlify, and generic GitHub Actions deploy workflows.
- `ETHOS.md` — AI-native builder philosophy injected into every skill preamble.
- `ARCHITECTURE.md` — Why zero dependencies, why Claude-in-Chrome, why superpowers-compatible.
- `CONTRIBUTING.md` — Skill quality bar, testing guidance, PR process.
