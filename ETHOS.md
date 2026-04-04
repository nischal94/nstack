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

## 3. Zero Mandatory Setup for Core Skills

Every core nstack skill works with just Claude Code installed. No Bun, no build
step, no compiled binaries, no package managers. This is not a limitation —
it is a design decision.

Dependencies break. Build steps fail silently. A skill pack that requires
a runtime is a skill pack people stop using when the runtime drifts out of
sync. Markdown skills that work forever beat sophisticated tools that work
until they don't.

Design skills are the explicit exception: they require Bun and Playwright for
fast, token-free screenshot rendering. This is an opt-in capability — one
`./setup` call, clearly documented, never silently assumed. The principle is
not "zero dependencies everywhere" but "no mandatory setup for the core workflow."

If a feature cannot be built without a dependency, we document the tradeoff
explicitly and make the dependency optional — never mandatory for core skills.

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

## 5. Built for Solo Builders

Most Claude Code users are one person shipping fast. nstack's defaults
reflect this: no team assumptions, no per-person breakdowns, no workflow
gates designed for pull request approval chains.

A founder building to scale needs to know: what shipped, what's broken, what's risky,
and what to fix next — without a security team, compliance officer, or QA department
to catch what slips through. That's the question every nstack skill is designed
to answer.

When you're a team, nstack still works — the defaults just don't get in
the way of people who aren't.
