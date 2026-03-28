---
name: investigate
description: Use when something is broken but you don't know where to start — a silent regression, unexpected behavior, rising error rates, cost spikes, or degraded output quality. Use when the user says "something broke", "this stopped working", "costs spiked", "outputs got worse", or "I don't know what changed".
---

# /investigate — Bug Triage

You are a senior engineer called in to triage an unknown failure. You don't touch code yet.
Your job: find the cause, build a hypothesis, assign a confidence rating.

**This skill is the entry point.** Once you have a hypothesis, hand off to
superpowers:systematic-debugging to fix it.

## Arguments

- `/investigate` — triage the most recent change that might be the culprit
- `/investigate "costs spiked after deploy"` — investigate a specific symptom
- `/investigate --since 2026-03-20` — scope to changes after a date
- `/investigate --file path/to/file.py` — focus on a specific file's history

---

## Step 1: Understand the symptom

Before touching git or code, ask (or infer from context):
- What is broken? (error message, wrong output, missing behavior, cost/latency spike)
- When did it start? (after a deploy, after a commit, after a config change, after a model update)
- Is it consistent or intermittent?
- What changed recently?

If the user gave a description, use it. If not, ask one focused question: "What are you seeing?"

---

## Step 2: Timeline reconstruction

```bash
# Recent commits — what changed?
git log --oneline -20

# Commits on a specific file
git log --oneline -20 -- path/to/file

# What changed in the last N commits?
git diff HEAD~5..HEAD --stat

# Who touched what recently
git log --since="7 days ago" --format="%h %s" --name-only
```

Build a mental timeline: what was deployed/merged when symptoms started?

---

## Step 3: Diff the suspect range

Once you have a suspect commit range:

```bash
# What actually changed?
git diff <before-sha>..<after-sha>

# Focused diff on suspect files
git diff <before-sha>..<after-sha> -- path/to/file.py
```

Read the diff. Look for:
- Logic changes near the reported symptom
- Config changes (model name, temperature, max_tokens, endpoint URLs)
- Dependency version bumps
- Environment variable changes
- Prompt text changes (for AI-native apps)

---

## Step 4: Search for the pattern

Use Grep to find all instances of the suspect pattern in the current codebase.

**For AI-native apps — common culprits:**

Prompt/model changes:
- Search for `model=`, `system=`, `max_tokens=`, `temperature=` near the suspect area
- Check if system prompt text changed (git diff on prompt files/constants)
- Check if user input handling changed (new sanitization, different truncation)

Cost spikes:
- Search for LLM call sites in loops: pattern `for.*\n.*client.messages` or similar
- Check if a new endpoint is calling the model per-item

Silent output degradation:
- Find where model output is post-processed — truncation, parsing, formatting
- Check if output validation was removed or relaxed

Error rate increases:
- Find the error type in logs/code
- Trace where it's thrown — what input triggers it?

---

## Step 5: Scope lock

Before forming a hypothesis, lock to the narrowest directory containing the suspect files.
This prevents investigation drift — accidentally reading or modifying unrelated code.

State the scope explicitly:
```
SCOPE LOCK
══════════
Investigating within: [path/to/suspect/directory/]
Reads outside this scope are allowed for context.
No code modifications in this session until hand-off to superpowers:systematic-debugging.
```

---

## Step 6: Hypothesis report

Track hypotheses with a strike counter. You get **3 strikes** — if 3 hypotheses fail to
be confirmed by evidence, stop and report rather than thrash.

Output a structured triage report:

```
INVESTIGATION REPORT  [Hypothesis #N of 3]
════════════════════
Symptom:     [What's broken]
First seen:  [Approximate time / commit]
Suspect:     [Commit SHA or file:line]

HYPOTHESIS
──────────
[1-3 sentence description of what you think happened and why]

Confidence:  N/10
Evidence:
  - [specific diff, line, or pattern that supports this]
  - [secondary evidence if any]

WHAT TO CHECK NEXT
──────────────────
1. [Most targeted verification step]
2. [Fallback if #1 doesn't confirm it]

HAND OFF
────────
Once confirmed: use superpowers:systematic-debugging to fix.
If hypothesis is wrong: [alternative to investigate — strike N of 3]
```

---

## Step 7: Three-strike rule

**Strike** = a hypothesis that the evidence does not support after verification.

After each failed hypothesis, increment the strike counter and state it clearly:
```
Strike 1 of 3 — Hypothesis ruled out. [Why it didn't hold.]
Moving to next hypothesis...
```

**After 3 strikes — STOP:**

```
3-STRIKE STOP
═════════════
Three hypotheses have been ruled out:
  1. [hypothesis 1] — ruled out because [reason]
  2. [hypothesis 2] — ruled out because [reason]
  3. [hypothesis 3] — ruled out because [reason]

The root cause is not in the obvious places. Options:

A) Add instrumentation — insert logging at key points and re-run the failing scenario
B) Bisect — use `git bisect` to find the exact commit that introduced the regression
C) Escalate — describe the failure in detail and use superpowers:systematic-debugging
   with the full investigation context attached
D) Expand scope — the bug may be outside [current scope]. Approve scope expansion.

What would you like to do?
```

Wait for the user's choice. Do not form a 4th hypothesis without explicit instruction.

---

## Step 8: Quick verification (non-destructive)

Before handing off, confirm or rule out the current hypothesis without changing code:

- Read the suspect file at the suspect line
- Check if the pattern appears elsewhere (variant search)
- Check git blame to confirm when the line was introduced
- Check if a related test exists and what it covers

```bash
git blame path/to/file.py | grep -n "suspect_function"
git log --oneline --follow -p -- path/to/file.py | head -80
```

Do NOT run the app, run tests, or modify any files in this phase.

---

## Rules

- **Hypothesis first, fix second.** Never suggest a fix until you have evidence.
- **One hypothesis at a time.** Don't list 5 possibilities — pick the most likely one.
- **Confidence must be earned.** If you can't find evidence, say confidence is 3/10, not 8/10.
- **3 strikes = stop.** Thrashing through hypotheses wastes time. Surface the impasse and ask.
- **Scope lock is not optional.** State the investigation boundary before forming any hypothesis.
- **AI-native regressions are subtle.** Model output degrading is not always a code bug — it may be a prompt change, a model version change, or a context length issue. Check all three.
- **Hand off, don't fix.** This skill ends at hypothesis + verification steps. Use superpowers:systematic-debugging for the fix.
