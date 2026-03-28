# Architecture

This document explains **why** nstack is built the way it is.
For setup and usage, see README.md. For contributing, see CONTRIBUTING.md.

---

## The core idea

nstack is pure markdown. No binaries, no build step, no runtime.

Every skill is a SKILL.md file that Claude Code discovers from `~/.claude/skills/nstack/`.
Claude reads the skill, follows the instructions, and uses its built-in tools
(Grep, Read, Bash, Agent) to execute the workflow. There is no nstack binary.
There is no server. There is nothing to compile.

This is a deliberate constraint. See "Why zero dependencies" below.

---

## Why zero dependencies

gstack requires Bun, a build step, compiled binaries, and Playwright.
This unlocks real capabilities — a persistent browser daemon, sub-100ms
command latency, native cookie decryption. Those are genuine advantages.

nstack makes a different bet: the constraint of zero dependencies is more
valuable than the capabilities those dependencies unlock.

**The install equation:**
- gstack: `git clone + cd + ./setup` (installs Bun if missing, compiles binaries, ~2 min)
- nstack: `git clone` (done, ~3 seconds)

**The failure equation:**
- gstack: Bun version mismatch, binary compilation failure, Playwright install, PATH issues
- nstack: Nothing to fail

For security tooling especially, a tool that silently fails to install is worse
than a simpler tool that always works. `/cso` running at 80% of gstack's depth
on every machine beats a theoretically deeper tool that half your machines
can't run.

---

## Why Claude-in-Chrome MCP for `/qa`

gstack's `/browse` uses a Playwright-based browser daemon. It's faster (~100ms/command)
and more automatable. nstack uses Claude-in-Chrome MCP instead. Here's why:

**You already have it.** Claude-in-Chrome MCP is installed as part of the standard
Claude Code setup. Zero additional install.

**It uses your real browser.** You're already logged into your staging environment,
your admin panel, your authenticated test pages. Playwright needs cookie import setup
to reach authenticated pages. Claude-in-Chrome is already there.

**It's observable.** When Claude-in-Chrome navigates and clicks, you can watch it
happen in your actual Chrome window. Playwright headless is invisible.

**The tradeoff:** Claude-in-Chrome is slower and less suited for fully automated
CI/CD test loops. If you need that, gstack's `/browse` is the better tool.
nstack's `/qa` is designed for interactive debugging sessions, not unattended pipelines.

---

## Why superpowers-compatible

nstack skills are designed to hand off to superpowers at natural boundaries:

| nstack skill | Hands off to | When |
|---|---|---|
| `/cso` | `superpowers:systematic-debugging` | When a finding needs root-cause investigation |
| `/cso` | `superpowers:verification-before-completion` | Before marking a finding remediated |
| `/qa` | `superpowers:requesting-code-review` | After fixing a bug found during QA |
| `/retro` | none | Self-contained retrospective |

This works because nstack and superpowers have non-overlapping scopes.
Superpowers covers the development workflow (plan → build → debug → review → ship).
nstack covers the quality layer on top (security audit → browser QA → retrospective).

There are no duplicate skill names. There are no conflicting invocation patterns.
When you type `/cso`, there is exactly one thing that can happen.

---

## Why `/cso` covers LLM security as a first-class concern

gstack's security audit has a Phase 7 for LLM security. It covers the basics:
prompt injection vectors, unsanitized output rendering, tool call validation.

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

- **No browser daemon.** That's gstack's territory and they do it well.
- **No CI/CD integration.** Skills are for interactive sessions, not pipelines.
- **No team workflow.** No PR approval chains, no multi-person retros.
- **No generated skill files.** Every SKILL.md is human-written, human-readable.
- **No telemetry.** Nothing is sent anywhere.
