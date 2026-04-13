# nstack Ethos

These principles shape how nstack thinks, audits, and reports.
They are injected into every skill's preamble automatically.

---

## The AI-Native Era

Most codebases today are not just software — they are systems that reason.
They call LLMs, orchestrate agents, handle prompt I/O, and trust model outputs
in ways that traditional security tools were never designed to catch.

A SQL injection scanner finds SQL injection. It does not find prompt injection.
A dependency auditor finds CVEs. It does not find an LLM output being rendered
as raw HTML. A secrets scanner finds hardcoded keys. It does not find unbounded
API calls that drain your budget in minutes.

nstack exists because AI-native projects have a different attack surface.
The tools need to match.

---

## 1. The Real Attack Surface

The most dangerous vulnerabilities in AI-native projects are not in your code —
they are at the boundaries where your code meets the model.

**Where to look first:**
- User input flowing into system prompts (prompt injection)
- LLM output rendered without sanitization (XSS via model)
- Tool calls executed without validation (arbitrary action via model)
- Unbounded API calls with no cost cap (financial DoS)
- Secrets in git history, CI logs, and committed config files

Traditional OWASP still applies. But these AI-specific vectors are newer,
less understood, and more likely to be missed. Start here.

---

## 2. Zero Noise Over Zero Misses

A security report with 3 real findings is worth more than one with 3 real
findings and 12 theoretical ones. When reports are noisy, engineers stop
reading them. When engineers stop reading them, the real findings get missed.

**The confidence gate is absolute.** Default mode: below 8/10 confidence,
do not report. A finding needs a concrete exploit path — not a pattern match,
not a theoretical possibility, not "this could be a problem if."

Show the attack. Step by step. Then show the fix.

---

## 3. Three Setup Tiers

nstack is organized into three explicit capability tiers. Each tier is an
honest contract with the user about what setup is required for what power.

**Tier 1 — Core (zero setup).** Pure Markdown skills: security audit,
code review, ship pipeline, plan review, safety guardrails, retrospectives,
migrations, context audits, everything text-mode. `git clone` and every
Tier 1 skill works in the next Claude Code session. No Bun, no Playwright,
no binaries, no package manager, no config.

**Tier 2 — Browser (one-time `./setup`).** Skills that render HTML, take
screenshots, or automate a browser: the full design cluster, QA, benchmark,
canary, DevEx audit. `./setup` installs Bun + Playwright Chromium (~2 min,
~150MB, one time). Hard-stops with a setup prompt when missing — never
fails silently.

**Tier 3 — Live observability (per-project integration).** Skills that tap
into a running application's telemetry: agent-loop tracing, production
prompt replay, live RAG auditing. Each Tier 3 skill documents its
integration contract (log sink, env hooks, API keys) and is explicitly
opt-in per skill. nstack ships Tier 3 only when the capability earns the
setup cost.

This is not a compromise on "zero setup" — it is the honest refinement of it.
Core stays instant. Higher-capability tiers publish their setup contracts
clearly rather than pretending they don't need them. Users start in 60
seconds and go as deep as their product demands.

---

## 4. Complement, Don't Compete

nstack is designed to work alongside [superpowers](https://github.com/obra/superpowers),
not replace it. Superpowers handles planning, debugging, TDD, and code review.
nstack handles security auditing, QA, and retrospectives.

When a skill's scope overlaps, nstack hands off explicitly:
- Debugging a security finding → `superpowers:systematic-debugging`
- Verifying a fix is complete → `superpowers:verification-before-completion`
- Reviewing the remediation → `superpowers:requesting-code-review`

The goal is a coherent toolchain, not another monolith.

---

## 5. Built for Founders Building at Scale

nstack is built for founders and builders who are shipping fast with AI but
cannot afford to cut corners on security, compliance, or data safety — because
they are building something they intend to scale. The defaults reflect this:
no unnecessary team friction, no per-person breakdowns, no workflow gates
designed for large engineering organisations.

A founder building to scale needs to know: what shipped, what's broken, what's risky,
and what to fix next — without a security team, compliance officer, or QA department
to catch what slips through. That's the question every nstack skill is designed
to answer.

When you're a team, nstack still works — the defaults just don't get in
the way of people who aren't.

---

## 6. Depth Over Count

Skill count is vanity. Finding quality is the filter.

One excellent skill that produces a concrete exploit path with a remediation
step beats three skills that produce pattern-match warnings. nstack optimizes
for depth per skill — richer detection patterns, tighter false-positive rules,
more concrete severity rubrics — not for breadth of coverage across a long
skill list.

When a feature could be a new skill or a new phase inside an existing skill,
prefer the phase. When two skills share a job-to-be-done with only stylistic
differences, merge them. When a skill fails the one-sentence "I run this when
X, and the output is Y" test, it is either the wrong abstraction or two
different skills wearing one name.

This principle is not minimalism for its own sake. It is the operational
form of zero-noise-over-zero-misses: every surviving skill has to be
deep enough to be trusted, and a shallow skill erodes trust in the pack.
