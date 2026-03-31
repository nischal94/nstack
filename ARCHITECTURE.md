# Architecture

This document explains **why** nstack is built the way it is.
For setup and usage, see README.md. For contributing, see CONTRIBUTING.md.

---

## Two tiers of capability

nstack splits into two tiers based on what you need.

**Tier 1 — Zero-setup core skills** (security, QA, retro, investigate, etc.)

Every skill is a SKILL.md file that Claude Code discovers from `~/.claude/skills/nstack/`.
Claude reads the skill, follows the instructions, and uses its built-in tools
(Grep, Read, Bash, Agent) to execute the workflow.

- `git clone` and done, ~3 seconds
- No build step, no binaries, no Bun
- Claude-in-Chrome MCP for `/qa` (authenticated pages, observable, already installed)
- Nothing to fail

**Tier 2 — Bun-powered browser CLI for design skills**

Design skills (`/design`, `/design-review`, `/design-shotgun`, `/design-consultation`, `/plan-design-review`) render HTML variants and take screenshots. For those, there is a Bun-compiled CLI entry point at `browse/dist/browse` backed by `browse/src/server.ts`.

- Run `./setup` once (~2 minutes on first install)
- Requires Bun at both install time and runtime (the CLI spawns a Bun server process on first use)
- Requires Playwright Chromium (~150MB, one-time download)
- `/design` and `/design-review` hard-stop with an install prompt if the binary is missing
- `/design-consultation`, `/design-shotgun`, `/plan-design-review` soft-skip screenshots and proceed without them
- No MCP fallback — MCP screenshot costs (base64 image data per call) make it unsuitable for design workflows that take 4–20 screenshots per run

This split preserves the zero-setup promise for core skills while unlocking full design capability for users who opt in.

---

## Why Playwright for design skills

Design skills generate 4–6 HTML variants per invocation and screenshot each. Claude-in-Chrome MCP works but costs tokens for every browser operation — batch rendering at that volume becomes expensive fast.

The Bun-compiled CLI renders screenshots at ~100ms each with no token cost after install. For design skills, speed and cost are what matter: no auth needed, headless is fine, and batch rendering is the whole job.

The CLI uses a persistent server daemon pattern — `browse/src/cli.ts` is a thin HTTP client that starts `browse/src/server.ts` as a background Bun process on first use and communicates via HTTP POST. Subsequent commands reuse the running daemon, giving sub-100ms round-trips. Because the server is a separate Bun process, Bun must remain on PATH after install — it is a runtime dependency, not just a build tool.

---

## Why Claude-in-Chrome MCP for `/qa` (and not design skills)

nstack uses two different browser strategies for two different problems.

**`/qa` uses Claude-in-Chrome MCP** because:
- You're already logged into staging, your admin panel, your authenticated test pages — Claude-in-Chrome is already there
- It's observable — you can watch Claude navigate your real Chrome window
- `/qa` is an interactive debugging session, not a batch rendering job

**Design skills use the Playwright binary exclusively** because:
- Design workflows take 4–20 screenshots per run; MCP returns base64 image data inline — that's hundreds of KB of tokens per screenshot
- Headless is fine for rendering static HTML variants — no auth, no real-browser state needed
- The binary renders at ~100ms per screenshot with zero token cost after install

MCP was removed from all design skills (`/design`, `/design-review`, `/design-shotgun`, `/design-consultation`, `/plan-design-review`) for this reason. The token cost was too high to justify as a fallback path.

---

## Why superpowers-compatible

nstack skills are designed to hand off to superpowers at natural boundaries:

| nstack skill | Hands off to | When |
|---|---|---|
| `/cso` | `superpowers:systematic-debugging` | When a finding needs root-cause investigation |
| `/cso` | `superpowers:verification-before-completion` | Before marking a finding remediated |
| `/qa` | `superpowers:requesting-code-review` | After fixing a bug found during QA |
| `/investigate` | `superpowers:systematic-debugging` | After identifying the suspect — to fix it |
| `/review` | `superpowers:verification-before-completion` | After auto-fixes are committed |
| `/autoplan` | `superpowers:executing-plans` | After plan is READY verdict |
| `/autoplan` | `superpowers:writing-plans` | When plan needs a full rewrite |
| `/ship` | `superpowers:requesting-code-review` | During the review step |
| `/premise` | `superpowers:brainstorming` | After CONFIRMED or NARROWED verdict |
| `/council` | `superpowers:writing-plans` | After consensus — to plan the execution |
| `/retro` | none | Self-contained retrospective |
| `/migrate` | none | Self-contained — runs its own verification |
| `/evals` | none | Self-contained — runs its own baseline comparison |
| `/context` | none | Self-contained — fixes issues inline |

This works because nstack and superpowers have non-overlapping scopes.
Superpowers covers the development workflow (plan → build → debug → review → ship).
nstack covers the quality layer on top (security audit → browser QA → retrospective).

There are no duplicate skill names. There are no conflicting invocation patterns.
When you type `/cso`, there is exactly one thing that can happen.

---

## Why `/cso` covers LLM security as a first-class concern

nstack makes LLM security the primary lens, not an afterthought. The attack
surface for AI-native projects is fundamentally different:

- The model is a new trust boundary that traditional scanners don't understand
- Prompt injection is the SQL injection of this decade
- Unbounded LLM calls are a financial DoS vector with no OWASP category
- RAG poisoning is a supply chain attack that affects model behavior, not code

nstack's `/cso` was designed with these vectors in mind from the start.
The 14-phase audit treats AI-specific vulnerabilities with the same rigor
as OWASP Top 10 — because they deserve it.

---

## Skill structure

Each skill follows this pattern:

```
skill-name/
  SKILL.md    ← the entire skill, self-contained
```

No templates, no generated files, no build step. What you read is what Claude runs.

SKILL.md frontmatter:
```yaml
---
name: skill-name
description: Use when [specific triggering conditions]
---
```

The description is critical — Claude uses it to decide which skills to load
for a given task. It must describe *when to use* the skill, not *what the skill does*.
See the [agentskills.io specification](https://agentskills.io/specification) for details.

---

## What nstack intentionally doesn't do

- **No CI/CD integration.** Skills are for interactive sessions, not pipelines.
- **No team workflow.** No PR approval chains, no multi-person retros.
- **No generated skill files.** Every SKILL.md is human-written, human-readable.
- **No telemetry.** Nothing is sent anywhere.
