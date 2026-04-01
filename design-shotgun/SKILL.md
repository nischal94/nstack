---
name: design-shotgun
description: Use when asked to "show me options", "generate variants", "multiple
  designs", or "explore directions". Explores several lightweight design
  directions quickly so the user can compare them and choose what to push
  further. Use when the direction is unclear, not when you need a full design
  system or a finished implementation plan. (nstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Agent
  - AskUserQuestion
---

## Binary detection

```bash
# Binary detection — nstack browse CLI
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  B="$NSTACK_BROWSE"
else
  B=""
  echo "[nstack] Browser binary not installed. HTML variants will be generated but not screenshotted."
  echo "  To enable screenshots: cd ~/.claude/skills/nstack && ./setup"
fi
```

If the binary is not installed, the skill proceeds without screenshots — variants are generated as HTML files only.

## Completion Status Protocol

When completing a skill workflow, report status using one of:
- **DONE** — All steps completed successfully. Evidence provided for each claim.
- **DONE_WITH_CONCERNS** — Completed, but with issues the user should know about. List each concern.
- **BLOCKED** — Cannot proceed. State what is blocking and what was tried.
- **NEEDS_CONTEXT** — Missing information required to continue. State exactly what you need.

### Escalation

It is always OK to stop and say "this is too hard for me" or "I'm not confident in this result."

Bad work is worse than no work. You will not be penalized for escalating.
- If you have attempted a task 3 times without success, STOP and escalate.
- If you are uncertain about a security-sensitive change, STOP and escalate.
- If the scope of work exceeds what you can verify, STOP and escalate.

Escalation format:
```
STATUS: BLOCKED | NEEDS_CONTEXT
REASON: [1-2 sentences]
ATTEMPTED: [what you tried]
RECOMMENDATION: [what the user should do next]
```

# /design-shotgun: Fast Direction Exploration

You are a design brainstorming partner. Generate multiple AI design variants, open them
side-by-side in the user's browser, and iterate until they approve a direction. This is
visual brainstorming, not a review process.

This skill is intentionally narrower than a full design platform.

Its role in nstack is:
- explore multiple directions quickly
- help the user compare them
- identify the direction worth carrying forward

Its role is NOT:
- define the whole design system, use `/design-consultation`
- critique a live product, use `/design-review`
- critique a written plan, use `/plan-design-review`
- promise a heavyweight generative design runtime just because gstack has one

The output of this skill is a clearer direction, not a finished design system or
an implementation-ready subsystem on its own.

## DESIGN SETUP (run this check BEFORE any design mockup command)

```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  echo "BROWSE_READY: $NSTACK_BROWSE"
else
  echo "BROWSE_NOT_AVAILABLE"
fi
```

This skill uses lightweight, inspectable HTML variants as its primary artifact.

If `BROWSE_NOT_AVAILABLE`, the skill still works. Show the HTML file paths and let
the user open them manually if they want a closer look.

**CRITICAL PATH RULE:** All design artifacts MUST be saved to `.nstack/design-shotgun/`.
Use `$TMPDIR` only as a staging area before copying to the final location.

## Step 0: Session Detection

Check for prior design exploration sessions for this project:

```bash
setopt +o nomatch 2>/dev/null || true
_PREV=$(find .nstack/design-shotgun/ -name "approved.json" -maxdepth 3 2>/dev/null | sort -r | head -5)
[ -n "$_PREV" ] && echo "PREVIOUS_SESSIONS_FOUND" || echo "NO_PREVIOUS_SESSIONS"
echo "$_PREV"
```

**If `PREVIOUS_SESSIONS_FOUND`:** Read each `approved.json`, display a summary, then
AskUserQuestion:

> "Previous design explorations for this project:
> - [date]: [screen] — chose variant [X], feedback: '[summary]'
>
> A) Revisit — reopen the comparison board to adjust your choices
> B) New exploration — start fresh with new or updated instructions
> C) Something else"

If A: regenerate the board from existing variant PNGs, reopen, and resume the feedback loop.
If B: proceed to Step 1.

**If `NO_PREVIOUS_SESSIONS`:** Show the first-time message:

"This is /design-shotgun — your lightweight visual brainstorming tool. I'll generate
multiple design directions, show them side-by-side, and help you pick what is worth
carrying forward. You can run /design-shotgun anytime during development to explore
design directions for any part of your product. Let's start."

## Step 1: Context Gathering

When design-shotgun is invoked from another skill, the calling skill has already gathered
context. Check for `$_DESIGN_BRIEF` — if it's set, skip to Step 2.

When run standalone, gather context to build a proper design brief.

**Required context (5 dimensions):**
1. **Who** — who is the design for? (persona, audience, expertise level)
2. **Job to be done** — what is the user trying to accomplish on this screen/page?
3. **What exists** — what's already in the codebase? (existing components, pages, patterns)
4. **User flow** — how do users arrive at this screen and where do they go next?
5. **Edge cases** — long names, zero results, error states, mobile, first-time vs power user

**Auto-gather first:**

```bash
cat DESIGN.md 2>/dev/null | head -80 || echo "NO_DESIGN_MD"
```

```bash
ls src/ app/ pages/ components/ 2>/dev/null | head -30
```

If DESIGN.md exists, tell the user: "I'll follow your design system in DESIGN.md by
default. If you want to go off the reservation on visual direction, just say so —
design-shotgun will follow your lead, but won't diverge by default."

**Check for a live site to screenshot** (for the "I don't like THIS" use case):

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "NO_LOCAL_SITE"
```

If a local site is running AND the user referenced a URL or said something like "I don't
like how this looks," screenshot the current page and use that screenshot as reference
for the HTML variants you generate. Do not assume a separate image-evolution runtime exists.

**AskUserQuestion with pre-filled context:** Pre-fill what you inferred from the codebase
and DESIGN.md. Then ask for what's missing. Frame as ONE question covering all gaps:

> "Here's what I know: [pre-filled context]. I'm missing [gaps].
> Tell me: [specific questions about the gaps].
> How many variants? (default 4, max 6)"

Two rounds max of context gathering, then proceed with what you have and note assumptions.

## Step 2: Taste Memory

Read prior approved designs to bias generation toward the user's demonstrated taste:

```bash
setopt +o nomatch 2>/dev/null || true
_TASTE=$(find .nstack/design-shotgun/ -name "approved.json" -maxdepth 3 2>/dev/null | sort -r | head -10)
```

If prior sessions exist, read each `approved.json` and extract patterns from the
approved variants. Include a taste summary in the design brief:

"The user previously approved designs with these characteristics: [high contrast,
generous whitespace, modern sans-serif typography, etc.]. Bias toward this aesthetic
unless the user explicitly requests a different direction."

Limit to last 10 sessions. Try/catch JSON parse on each (skip corrupted files).

## Step 3: Generate Variants

Set up the output directory:

**Before running the command below:** replace `<screen-name>` with the actual descriptive kebab-case name from your context gathering (e.g. `onboarding`, `dashboard`, `pricing`). Do not run this block with the angle-bracket placeholder intact.

```bash
_DESIGN_DIR=$(pwd)/.nstack/design-shotgun/<screen-name>-$(date +%Y%m%d)
mkdir -p "$_DESIGN_DIR"
echo "$_DESIGN_DIR" > "$TMPDIR/design-shotgun-dir"
echo "DESIGN_DIR: $_DESIGN_DIR"
```
`_DESIGN_DIR` is persisted to `$TMPDIR/design-shotgun-dir`. Each subsequent Bash block that needs it must re-read: `_DESIGN_DIR="$(cat "$TMPDIR/design-shotgun-dir")"` — shell variables do not persist across Bash calls.

### Step 3a: Concept Generation

Before any generation, produce N text concepts describing each variant's design direction.
Each concept should be a distinct creative direction, not a minor variation. Present them
as a lettered list:

```
I'll explore 4 directions:

A) "Name" — one-line visual description of this direction
B) "Name" — one-line visual description of this direction
C) "Name" — one-line visual description of this direction
D) "Name" — one-line visual description of this direction
```

Draw on DESIGN.md, taste memory, and the user's request to make each concept distinct.
Different hierarchy, density, composition, and tone. Not just color swaps.

### Step 3b: Concept Confirmation

Use AskUserQuestion to confirm before generating:

> "These are the {N} directions I'll generate as lightweight HTML variants."

Options:
- A) Generate all {N} — looks good
- B) I want to change some concepts (tell me which)
- C) Add more variants (I'll suggest additional directions)
- D) Fewer variants (tell me which to drop)

If B: incorporate feedback, re-present concepts, re-confirm. Max 2 rounds.
If C: add concepts, re-present, re-confirm.
If D: drop specified concepts, re-present, re-confirm.

### Step 3c: Parallel Generation

**If evolving from a screenshot** (user said "I don't like THIS"), take ONE screenshot
first:

```bash
$B screenshot "$_DESIGN_DIR/current.png"
```

**Launch N Agent subagents in a single message** (parallel execution). Dispatch all
variants simultaneously using multiple Agent tool calls in one message. Each agent is
independent and writes one self-contained HTML variant.

**Before dispatching agents:** Resolve shell variables to literal values — agents don't inherit the parent shell's environment:
```bash
echo "$TMPDIR"
echo "$_DESIGN_DIR"
```
Substitute both results into each agent prompt. Do NOT pass `$TMPDIR` or `$_DESIGN_DIR` as shell variables.

**Agent prompt template** (one per variant, substitute all `{...}` values):

```
Generate one lightweight design exploration variant and save it as HTML.

Variant: {letter}
Direction: {variant-specific concept}
Brief: {the full variant-specific brief for this direction}
Output: <resolved-TMPDIR>/design-shotgun-variant-{letter}.html
Final location: {_DESIGN_DIR absolute path}/variant-{letter}.html

Requirements:
- Fully self-contained HTML
- Inline CSS only
- No external dependencies
- Realistic content, not lorem ipsum
- Distinct hierarchy and layout from the other variants
- Match DESIGN.md if present

Steps:
1. Write the HTML file to <resolved-TMPDIR>/design-shotgun-variant-{letter}.html
2. Copy it to {_DESIGN_DIR}/variant-{letter}.html
3. Report exactly one of:
   VARIANT_{letter}_DONE
   VARIANT_{letter}_FAILED: {error}
```

**Why $TMPDIR then cp?** Generating directly to `~/.nstack/...` can fail with sandbox
restrictions. Always generate to `$TMPDIR` first, then `cp` to the final location.

### Step 3d: Results

After all agents complete:

1. Read each generated HTML file inline (Read tool) so the user sees all variants at once.
2. Report status: "All {N} variants generated. {successes} succeeded, {failures} failed."
3. For any failures: report explicitly with the error. Do NOT silently skip.
4. If zero variants succeeded: fall back to sequential generation (one at a time,
   showing each as it lands).
5. Proceed to Step 4 (comparison and selection).

## Step 4: Comparison And Selection

If browse is available, screenshot each variant so the user can compare them inline:

```bash
_DESIGN_DIR="$(cat "$TMPDIR/design-shotgun-dir")"
mkdir -p "$_DESIGN_DIR/screenshots"
for f in "$_DESIGN_DIR"/variant-*.html; do
  [ -f "$f" ] || continue
  _name=$(basename "$f" .html)
  "$B" goto "file://$f"
  "$B" screenshot "$_DESIGN_DIR/screenshots/${_name}.png"
done
```

Use the Read tool on each generated PNG.

If browse is not available:
- show the HTML file paths
- tell the user to open them locally if they want closer inspection

Then use AskUserQuestion:

> "Which direction should we carry forward?
> A) Variant A
> B) Variant B
> C) Variant C
> D) Blend specific elements
> E) None of these, generate a new round"

If the user chooses D:
- ask for one concise blend instruction
- generate one additional HTML variant that combines the selected elements
- show it
- confirm again

If the user chooses E:
- go back to Step 3 with a revised brief
- do not keep generating indefinitely, two rounds max unless the user explicitly wants more

## Step 5: Feedback Confirmation

After receiving feedback, output a clear
summary confirming what was understood:

"Here's what I understood from your feedback:

PREFERRED: Variant [X]
RATINGS: A: 4/5, B: 3/5, C: 2/5
YOUR NOTES: [full text of per-variant and overall comments]
DIRECTION: [regenerate action if any]

Is this right?"

Use AskUserQuestion to confirm before saving.

## Step 6: Save & Next Steps

**Save the approved choice** using the Write tool to ensure proper JSON encoding:

Write the following JSON to `$_DESIGN_DIR/approved.json` using the `Write` tool (not shell echo — feedback text may contain quotes that would corrupt shell-interpolated JSON):
```json
{
  "approved_variant": "<V>",
  "feedback": "<FB — escape any quotes>",
  "date": "<ISO timestamp>",
  "screen": "<SCREEN>",
  "branch": "<current branch>"
}
```

If invoked from another skill: return the structured feedback for that skill to consume.
The calling skill reads `approved.json` and the approved variant HTML.

If standalone, offer next steps via AskUserQuestion:

> "Design direction locked in. What's next?
> A) Iterate more — refine the approved variant with specific feedback
> B) Apply it — use `/design` to adapt this direction into the project
> C) Save to plan — add this as an approved direction reference in the current plan
> D) Done — I'll use this later"

## Important Rules

1. **Never save to `.context/`, `docs/designs/`, or `/tmp/`.** All design artifacts go
   to `.nstack/design-shotgun/`. Use `$TMPDIR` only as a staging area before copying
   to the final location.
2. **Show variants inline before asking for a decision.** The user should see the
   designs before they choose.
3. **Confirm feedback before saving.** Always summarize what you understood and verify.
4. **Taste memory is automatic.** Prior approved designs inform new generations by default.
5. **Two rounds max on context gathering.** Don't over-interrogate. Proceed with assumptions.
6. **DESIGN.md is the default constraint.** Unless the user says otherwise.
7. **Parallel dispatch is preferred for 2+ variants.** Use multiple Agent tool calls
   in a single message when practical. Fall back to sequential only if needed.
8. **This is a direction tool, not a design platform.** Keep the workflow lightweight,
   inspectable, and grounded in HTML artifacts.
