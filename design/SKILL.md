---
name: design
description: Use when asked to "design this", "make it look good", "generate UI", or "build the frontend". Default mode generates 2-3 HTML design directions, helps the user pick one, and packages the approved direction as a reference for the normal coding workflow. Use `/design sketch N` when the direction is unclear and you need multiple visual options quickly — the user says "show me options", "generate variants", "explore directions", or "design brainstorm". For design-system work, use /design-consultation. For critique, use /design-review or /plan-design-review.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
  - WebSearch
---

# /design: UI Direction Generation

Two modes:

- **`/design`** (default) — generates 2-3 HTML design directions, helps the user pick one, and packages the approved direction as a durable design reference. Use when you need ONE direction to move forward with.
- **`/design sketch N`** — exploration mode. Generates N HTML variants in parallel, presents them as a comparison board, and helps the user identify a direction (or blend elements) — WITHOUT committing to an approved package. Use when the direction is still fuzzy and you want to see options before locking in.

Both modes share the same rendering machinery (parallel Agent-dispatched HTML generation, browse-binary screenshots, DESIGN.md honoring). They differ in count, output artifact, and whether the flow commits to a final direction.

---

## Default mode (`/design`)

Gets a project from "we need a UI direction" to "we have one coherent direction we can follow."

What default mode produces:
- 2-3 HTML design directions with realistic content
- screenshots when the browse binary is available
- one approved direction packaged as a durable design reference

What this skill does NOT produce:
- a full design system — use `/design-consultation`
- an exhaustive design critique — use `/design-review`
- direct implementation in the project codebase

If a `DESIGN.md` exists, it is binding. This skill explores layout, hierarchy,
and component direction inside that system. It does not invent a new visual
language.

When this skill finishes successfully, the next likely step is:
- normal implementation work in the real codebase
- `/design-review` after the implemented result exists
- `/plan-design-review` if the design direction exposed missing plan decisions

## Browser Detection (run first)

```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  B="$NSTACK_BROWSE"
else
  echo "[nstack] Browser binary not installed. /design requires the nstack browser binary."
  echo "  Install it: cd ~/.claude/skills/nstack && ./setup"
  exit 1
fi
```

Hard gate: if the binary is not installed, stop here. Show the install command and exit.

If the user says "no browser": skip Phases 4 and 5. Show the HTML file paths and ask the user to open them manually. Ask which variant they prefer, then proceed to Phase 6.

## Phase 1: Codebase Read

Read the project to understand what exists before generating anything.

```bash
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || echo "NO_PACKAGE_FILE"
```

- Check for `DESIGN.md` in the project root. If found, load it — it is a binding design system constraint.
- Scan for existing UI patterns: CSS files, component directories (`components/`, `src/`, `app/`), template files (`.html`, `.tsx`, `.vue`, `.erb`, `.jinja`).
- Note the tech stack. This matters for the handoff note so the next coding step
  knows what kind of UI layer will consume the approved direction.

```bash
cat DESIGN.md 2>/dev/null || echo "NO_DESIGN_MD"
```

```bash
ls src/ app/ pages/ components/ templates/ 2>/dev/null | head -40
```

## Phase 2: Brief

Ask the user ONE question. Cover all four dimensions in a single prompt — don't run a multi-turn interview.

Use AskUserQuestion:

> **What are we designing?**
>
> Help me understand:
> 1. What does this UI do? (one sentence on the job to be done)
> 2. Who uses it? (internal tool, consumer app, developer dashboard, etc.)
> 3. Aesthetic direction preference: minimal/clean, bold/expressive, or data-dense/utility
> 4. Any reference sites or apps you like the look of? (optional)

If `DESIGN.md` exists, skip question 3 — the aesthetic direction is already set. Say so: "I'll follow the direction in DESIGN.md. Just tell me what the UI does and who it's for."

Keep the question short. The user doesn't need to write an essay to get a good design.

## Phase 3: Parallel Variant Generation

Use the Agent tool to dispatch 3 subagents in parallel. Each agent writes one complete self-contained HTML file.

**Before dispatching:** Resolve `$TMPDIR` to its literal value with a Bash call:
```bash
echo "$TMPDIR"
```
Substitute the resolved path (e.g. `/var/folders/xx/.../T/`) into each agent prompt below. Do NOT pass `$TMPDIR` as a shell variable — agents don't inherit shell state.

Dispatch all three at once:

**Agent 1 — minimal/clean:**
Write a complete HTML file to `<resolved-TMPDIR>/design-variant-1.html`.

Design direction: white space, single accent color, clean typography, subtle borders. The kind of interface that feels calm and confident. Think Linear, Stripe, or Vercel.

Requirements:
- Inline CSS only. No external CDN links, no Google Fonts, no remote anything.
- Realistic placeholder content that matches the app's actual purpose (from the brief). Not "Lorem ipsum" — real-looking names, realistic data, plausible copy.
- At least 3 sections: header/nav, main content area, footer or CTA zone.
- Show enough UI to make a real design decision. Not color swatches — an actual page layout with components.
- Assume 1200px wide viewport.

**Agent 2 — bold/expressive:**
Write a complete HTML file to `<resolved-TMPDIR>/design-variant-2.html`.

Design direction: strong colors, large type, high contrast, personality. The kind of interface that makes an impression. Think Superhuman, Loom, or early Stripe's landing pages.

Same requirements as Agent 1.

**Agent 3 — data-dense/utility:**
Write a complete HTML file to `<resolved-TMPDIR>/design-variant-3.html`.

Design direction: information-rich layout, compact spacing, utility-first. The kind of interface that respects the user's time and puts everything they need in view. Think GitHub, Linear's issue list, or a Bloomberg terminal that doesn't make your eyes bleed.

Same requirements as Agent 1.

**If DESIGN.md exists:** All three variants must honor its color palette and typography. Vary layout and component density only — do not override brand colors or typefaces.

Each agent must confirm the file was written before returning. If a file write fails, the agent should report the error.

## Phase 4: Screenshot Each Variant

```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
_TMPDIR="$TMPDIR"
_PWD="$(pwd)"
mkdir -p "${_PWD}/.nstack/design"
"$NSTACK_BROWSE" goto "file://${_TMPDIR}/design-variant-1.html"
"$NSTACK_BROWSE" screenshot "${_PWD}/.nstack/design/variant-1.png"

"$NSTACK_BROWSE" goto "file://${_TMPDIR}/design-variant-2.html"
"$NSTACK_BROWSE" screenshot "${_PWD}/.nstack/design/variant-2.png"

"$NSTACK_BROWSE" goto "file://${_TMPDIR}/design-variant-3.html"
"$NSTACK_BROWSE" screenshot "${_PWD}/.nstack/design/variant-3.png"
```

After each screenshot, show it immediately with the Read tool so the user sees all three before choosing.

## Phase 5: Selection

After all three screenshots are shown, ask:

Use AskUserQuestion:

> **Which direction resonates?**
>
> - Variant 1 (minimal/clean)
> - Variant 2 (bold/expressive)
> - Variant 3 (data-dense/utility)
>
> Options:
> A) Variant 1
> B) Variant 2
> C) Variant 3
> D) Blend — describe what you want (e.g., "layout of 1, colors of 2")
> E) None — start over with different direction

If the user picks a single variant, proceed to Phase 6.

If the user requests a blend (D): re-resolve TMPDIR (do not rely on the Phase 4 value across the AskUserQuestion boundary):
```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
_TMPDIR="$TMPDIR"
_PWD="$(pwd)"
```
Produce a 4th HTML file at `<resolved-TMPDIR>/design-variant-4.html` that combines the requested elements. Then:
```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
_TMPDIR="$TMPDIR"
_PWD="$(pwd)"
"$NSTACK_BROWSE" goto "file://${_TMPDIR}/design-variant-4.html"
"$NSTACK_BROWSE" screenshot "${_PWD}/.nstack/design/variant-4.png"
```
Show it with Read. Confirm before proceeding.

If the user wants to inspect a variant more closely:
```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
_TMPDIR="$TMPDIR"
"$NSTACK_BROWSE" goto "file://${_TMPDIR}/design-variant-{N}.html"
```

If no option satisfies: go back to Phase 2 with new direction from the user.

## Phase 6: Package The Approved Direction

Do not implement the design in the project codebase.

Instead, package the approved direction so the normal coding workflow can build
it intentionally.

Create `.nstack/design/final/` and write:
- `approved.html` — the approved variant as the canonical visual reference
- `APPROVED_DIRECTION.md` — a short design-reference note for the coding workflow

`APPROVED_DIRECTION.md` should capture:
- what screen/page this design is for
- the core layout structure
- the main components and sections
- important responsive behavior
- key visual rules that should not drift
- open questions or decisions still needing confirmation
- the detected UI layer or stack from Phase 1

If the approved direction is a blend, make sure `approved.html` reflects the
blended result rather than pointing at an earlier variant.

Show a short completion summary:
- which variant was approved
- where `approved.html` was written
- where `APPROVED_DIRECTION.md` was written
- the recommended next step: use the normal coding workflow to build it, then run `/design-review`

## Phase 7: Close Cleanly

Do not claim the design has been implemented.

End by stating:
- the design direction is approved
- the reference artifacts are ready
- actual coding happens in the normal project workflow
- `/design-review` should be used after the UI exists in the real product

---

## Sketch mode (`/design sketch N`)

Exploration mode. Use when the user isn't ready to commit to one direction and wants to see multiple options side-by-side.

**Invocation:** `/design sketch 4` generates 4 variants. `/design sketch` without a number defaults to 4. Sensible range: 3-6. Above 6 becomes hard to compare meaningfully.

### Sketch phase 1: Same brief, broader net

Run **Phase 1 (Codebase Read)** and **Phase 2 (Brief)** exactly as in default mode. DESIGN.md if present is still binding.

### Sketch phase 2: Parallel N-variant generation

Dispatch N Agents in parallel (not just 3). Use varied aesthetic directions per variant — do not repeat directions:

- Minimal/clean (Linear, Stripe, Vercel)
- Bold/expressive (Superhuman, Loom)
- Data-dense/utility (GitHub, Linear issue list, Bloomberg)
- Editorial/magazine (Medium, long-form product pages)
- Playful/illustrative (Figma community, Notion marketing)
- Brutal/raw (Hacker News, Craigslist-inspired)

Pick N distinct directions from the list (or adjacent) — one per agent. Each agent writes `<resolved-TMPDIR>/design-variant-{letter}.html` with the same requirements as default mode (inline CSS, realistic content, 3+ sections, 1200px viewport).

### Sketch phase 3: Comparison board

Screenshot each variant (same browse-binary flow as default mode Phase 4). Save all screenshots to `.nstack/design/sketch-{YYYY-MM-DD}/variant-{letter}.png`.

Show all N screenshots via the Read tool in sequence so the user can compare them inline.

### Sketch phase 4: Identify direction (not commit)

Use AskUserQuestion:

> **What direction feels right?**
>
> - Pick one to move forward with (I'll package it as an approved direction via default mode)
> - Blend — describe what to combine (e.g., "layout of A with colors of D")
> - Keep exploring — generate another round with adjusted direction
> - Save findings — write a `sketch-notes.md` summary of what we learned without committing

**If the user picks one to move forward:** hand off into default mode Phase 6 (Package The Approved Direction) using the chosen variant. The sketch mode has served its purpose.

**If the user requests a blend:** generate one additional variant that combines the requested elements, screenshot it, show it, confirm. Then hand off to Phase 6.

**If the user wants to keep exploring:** revise the brief based on what resonated and what didn't, then run sketch phase 2 again with refreshed directions.

**If the user wants save findings:** write `.nstack/design/sketch-{YYYY-MM-DD}/sketch-notes.md` capturing:
- The brief
- Which variants resonated and why
- Which directions to revisit
- Open questions for the next design session

Close without packaging an approved direction. The sketch mode is exploratory — it's OK to leave without a commit.

### When to use sketch mode vs default

| Situation | Mode |
|-----------|------|
| "We need to ship a UI direction, help me pick one" | `/design` |
| "I don't know what this should look like yet" | `/design sketch 4` |
| "Show me what's possible before I decide" | `/design sketch 5` |
| "I want to see 3 options and commit to one" | `/design` (it already does this) |

---

## Rules

1. Never commit files without asking first.
2. Show screenshots to the user immediately after capturing — use the Read tool on each PNG before moving on.
3. If the user says "no browser," skip Phases 4 and 5 (default) or sketch phase 3. Show the HTML file paths and ask the user to open them manually.
4. DESIGN.md constraints are non-negotiable. Never override its color palette or typography. If the user asks you to, clarify that DESIGN.md is a binding constraint and ask if they want to update the file first.
5. Each variant must be genuinely different — not color swaps on the same layout. Different structural approaches, different information hierarchy, different spatial rhythms.
6. **Sketch mode has no commit.** It is explicitly exploratory. Don't pressure the user to pick one at the end of a sketch session — "keep exploring" and "save findings" are legitimate outcomes.
7. Sketch artifacts go to `.nstack/design/sketch-{YYYY-MM-DD}/`. Default mode artifacts go to `.nstack/design/final/`. The two directories don't collide.
