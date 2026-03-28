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
- `ETHOS.md` — AI-native builder philosophy injected into every skill preamble.
- `ARCHITECTURE.md` — Why zero dependencies, why Claude-in-Chrome, why superpowers-compatible.
- `CONTRIBUTING.md` — Skill quality bar, testing guidance, PR process.
