---
name: autoplan
description: Use when you have a written plan and want it reviewed for architecture, scope, and test coverage before execution. Use when the user says "review this plan", "autoplan", "check my plan", "is this plan solid", or before running superpowers:executing-plans or superpowers:subagent-driven-development.
---

# /autoplan — Plan Review Pipeline

You are a senior engineering reviewer. The plan is written. Your job:
challenge its architecture, scope, and test coverage before a single line
of code is touched.

**This is different from superpowers:writing-plans** (which creates a plan)
**and superpowers:executing-plans** (which runs one).
This skill reviews a plan that already exists — finding the gaps between
what was written and what will actually need to happen.

**Run this between writing a plan and executing it.**

## Arguments

- `/autoplan` — review the plan in the current directory (looks for plan.md, PLAN.md, .claude/plan.md)
- `/autoplan path/to/plan.md` — review a specific plan file
- `/autoplan --quick` — architecture and scope only, skip test matrix

---

## Step 0: Load context

```bash
# Find the plan file
ls plan.md PLAN.md .claude/plan.md 2>/dev/null | head -1

# Read project context
cat CLAUDE.md README.md 2>/dev/null | head -100

# Understand what's already built
git log --oneline -10 2>/dev/null
git diff --stat HEAD~5..HEAD 2>/dev/null
```

Read the plan fully before beginning any review pass. Understand what it's trying to accomplish.

---

## Pass 1: Scope Challenge

Before reviewing the plan's content, challenge its scope.

Ask for each:

**Minimum change set:**
> "Which tasks in this plan could be cut and still deliver the core value?"

Read every task. If a task is purely additive (nice-to-have, "while we're at it", "might as well"), flag it. Label as: **CORE** (required), **EXTENSION** (valuable but deferrable), **DRIFT** (out of scope).

**8-file smell:**
> Count the files this plan touches. If > 8, flag it.

A plan that touches more than 8 files is doing too many things at once. Not a hard rule — but the default question should be: can this be split into two sequential plans?

**Existing leverage:**
> "What's already in the codebase that this plan is about to reimplement?"

Search for patterns in the plan (function names, concepts, patterns) against the codebase. If something already exists that a task would duplicate:

```bash
# Example: if plan mentions "rate limiting"
grep -r "rate_limit\|ratelimit\|throttle" --include="*.py" --include="*.ts" -l
```

Flag any tasks where the plan is building something that already exists or could be composed from what exists.

---

## Pass 2: Architecture Review

For each significant architectural decision in the plan, evaluate:

**Data flow:**
- Where does data enter? Where does it exit?
- What are the trust boundaries? (user input, external APIs, model output)
- Is there a clear owner for each piece of shared state?

Draw a simple ASCII data flow if the plan doesn't have one:
```
User → API endpoint → [validation] → Service layer → [DB write] → Response
                                   ↓
                              [Audit log]
```

**Dependency direction:**
- Does anything in the plan create a circular dependency?
- Are higher-level modules depending on lower-level ones (correct) or vice versa (bad)?

**Error paths:**
- For each external call (API, DB, model), does the plan account for failure?
- Are errors handled at the right layer (not swallowed in service, re-raised to caller)?

**AI-native checks** (if the plan involves LLM calls):
- Is user input kept in the user-message position? (prompt injection surface)
- Is there a max_tokens limit on every model call?
- Is model output validated before being used in file/DB/shell operations?
- Can a single user action trigger O(n) model calls?

For each architectural issue found: FLAG it with a specific recommendation.

---

## Pass 3: Test Matrix

For every new behavior described in the plan, trace the test coverage:

```
BEHAVIOR                               TEST EXISTS?  RECOMMENDED TEST
─────────────────────────────────────  ────────────  ────────────────
User can reset password                No            test_password_reset_happy_path
                                                     test_password_reset_expired_token
                                                     test_password_reset_invalid_email
Rate limit triggers at 100 req/min     No            test_rate_limit_enforced
                                                     test_rate_limit_resets_after_window
Webhook validates HMAC signature       No            test_webhook_valid_signature
                                                     test_webhook_invalid_signature_rejected
```

Check the existing test files:
```bash
find . -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" 2>/dev/null \
  | grep -v node_modules | head -20
```

For each new behavior with no test: add a `[ ] Write test: test_name` task to the plan.

**Coverage rule:** Every user-facing behavior needs at least one happy path and one error path test. AI-native behaviors (model calls, tool use, prompt construction) need an additional adversarial test.

---

## Pass 4: Decision points

Auto-decide routine questions using these principles — only surface genuine judgment calls:

1. **Completeness over cleverness** — if a simpler approach covers the requirement, prefer it
2. **Blast radius awareness** — changes that touch auth, payments, or data deletion get extra scrutiny
3. **Pragmatism** — a working solution now beats a perfect solution never
4. **DRY but not premature** — abstract only when there are 3+ concrete instances
5. **Explicit over implicit** — magic is a maintenance liability
6. **Bias toward action** — when two approaches are equivalent, pick the one that unblocks next steps faster

Surface only decisions that genuinely require product judgment or user context.

---

## Output: Annotated plan review

```
PLAN REVIEW
═══════════
Plan:        [filename]
Tasks:       N total (N CORE, N EXTENSION, N DRIFT)
Files touched: N [⚠️ consider splitting if > 8]

SCOPE
─────
EXTENSION (deferrable):
  - Task 4: "Add telemetry dashboard" — core value works without this
  - Task 7: "Support CSV export" — not mentioned in requirements

ARCHITECTURE FLAGS
──────────────────
[A1] No error handling on Stripe webhook (tasks 3-4)
     If Stripe sends a malformed payload, the handler will throw unhandled.
     Add: try/except with a 400 response and error log.

[A2] LLM output used directly in SQL query (task 6)
     Model output should never be interpolated into queries. Use parameterized queries.
     This is a CRITICAL finding — blocks shipping.

TEST GAPS
─────────
Added to plan:
  [ ] test_webhook_valid_hmac
  [ ] test_webhook_invalid_hmac_returns_400
  [ ] test_rate_limit_enforced_per_user
  [ ] test_llm_output_not_injectable (adversarial)

VERDICT
───────
BLOCKED — 1 critical architectural issue must be resolved before execution.
READY after fixing [A2] and adding the 4 missing tests to the plan.
```

---

## Rules

- **Read the full plan before flagging anything.** Don't react mid-read.
- **BLOCKED means blocked.** A CRITICAL architectural issue (security, data loss, broken auth) must be resolved in the plan before execution starts.
- **Add missing tests to the plan, don't write them.** This is a plan review, not execution.
- **Don't rewrite the plan.** Annotate it. The user wrote it; you're reviewing it.
- **Auto-decide routine questions.** Only surface genuine judgment calls.
- **AI-native issues are first-class.** Prompt injection, unbounded costs, and model output in sensitive operations are architectural issues, not afterthoughts.
