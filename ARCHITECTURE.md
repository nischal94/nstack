# Architecture

This document explains **why** nstack is built the way it is.
For setup and usage, see README.md. For contributing, see CONTRIBUTING.md.

---

## Two tiers of capability

nstack has two tiers with different runtime contracts. Understanding the split matters before installing.

---

**Tier 1 — Core skills (zero setup)**

22 skills: security, QA, bug triage, retrospectives, release, workflow guardrails, and more.

Every core skill is a single `SKILL.md` file. Claude Code discovers it from `~/.claude/skills/nstack/`, reads it, and executes the workflow using its built-in tools (Grep, Read, Bash, Agent).

- `git clone` and done — no build step, no binaries, no package manager
- `/qa` uses Claude-in-Chrome MCP, which is already installed if you use Claude Code
- Nothing to install, nothing to fail

This is the "zero mandatory setup" claim. It applies to Tier 1 only.

---

**Tier 2 — Design skills (requires Bun + Playwright)**

5 skills: `/design`, `/design-review`, `/design-shotgun`, `/design-consultation`, `/plan-design-review`.

These skills render HTML variants and take screenshots. They use a Bun-powered CLI (`browse/`) — a compiled entry point (`browse/dist/browse`) that spawns `browse/src/server.ts` as a background Bun process on first use.

**Runtime contract:**
- Bun must be installed and on PATH — it is required at runtime, not just build time
- Playwright Chromium must be downloaded (~150MB, one-time)
- Run `./setup` once to satisfy both requirements (~2 minutes)

**Behavior when setup is missing:**
- `/design` and `/design-review` hard-stop with an install prompt
- `/design-consultation`, `/design-shotgun`, `/plan-design-review` soft-skip screenshots and proceed

This is an intentional opt-in tier. The runtime requirement is real and documented — not a footnote.

The design cluster is intentionally narrower than gstack's design subsystem.
Its purpose is to add design judgment, direction-setting, and critique to the
builder workflow, not to reproduce every part of a heavyweight design platform.

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

The same idea applies inside the design cluster:
- `/design-consultation` owns the design system
- `/plan-design-review` owns pre-build critique
- `/design` owns first-direction generation
- `/design-shotgun` owns quick exploration when direction is unclear
- `/design-review` owns live-product polish

The cluster is meant to be coherent and selective, not exhaustive.

Read as a chain, the design flow is:

1. `/design-consultation` establishes the visual system and writes `DESIGN.md`
2. `/plan-design-review` critiques the intended UI before code is written
3. `/design-shotgun` explores alternative directions when the answer is not obvious
4. `/design` locks one coherent direction and turns it into an approved implementation reference
5. normal implementation work builds the product in the actual codebase
6. `/design-review` audits the built result and tightens polish

This matters because nstack does not include a separate design-only production
pipeline. The handoff is from design judgment to ordinary implementation work,
not from one internal design runtime to another.

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
