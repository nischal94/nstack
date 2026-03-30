---
name: design
description: Use when asked to "design this", "make it look good", "generate UI",
  or "build the frontend". Reads the codebase, generates multiple HTML design
  variants, screenshots each, picks the best, and applies it to the project.
  Proactively suggest when the user has no existing UI. (nstack)
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

# /design: UI Generation with Parallel Variant Selection

Generate multiple design variants, screenshot each, let the user pick, then apply the chosen design to the actual project.

## Browser Detection (run first)

```bash
NSTACK_BROWSE="$HOME/.claude/skills/nstack/browse/dist/browse"
if [ -x "$NSTACK_BROWSE" ]; then
  B="$NSTACK_BROWSE"
  BROWSE_MODE="binary"
else
  B=""
  BROWSE_MODE="mcp"
  echo "[nstack] Browser binary not installed. Using Claude-in-Chrome MCP (slower, more token-intensive)."
  echo "  For faster rendering: cd ~/.claude/skills/nstack && ./setup"
fi
```

When `BROWSE_MODE="binary"`: use `$B <command>` for all browser operations.
When `BROWSE_MODE="mcp"`: use `mcp__claude-in-chrome__navigate` and `mcp__claude-in-chrome__computer` for navigation and screenshots.

If binary absent AND MCP unavailable:

```
[nstack] No browser available. /design requires either:
  1. nstack browser binary: cd ~/.claude/skills/nstack && ./setup
  2. Claude-in-Chrome MCP running in this session
```

Hard gate: if no browser is available, stop here. Show the HTML file paths and ask the user to open them manually for review.

## Phase 1: Codebase Read

Read the project to understand what exists before generating anything.

```bash
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || echo "NO_PACKAGE_FILE"
```

- Check for `DESIGN.md` in the project root. If found, load it — it is a binding design system constraint.
- Scan for existing UI patterns: CSS files, component directories (`components/`, `src/`, `app/`), template files (`.html`, `.tsx`, `.vue`, `.erb`, `.jinja`).
- Note the tech stack. This matters for Phase 6 — React needs components, Django needs templates, plain HTML is write-in-place.

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

Dispatch all three at once:

**Agent 1 — minimal/clean:**
Write a complete HTML file to `$TMPDIR/design-variant-1.html`.

Design direction: white space, single accent color, clean typography, subtle borders. The kind of interface that feels calm and confident. Think Linear, Stripe, or Vercel.

Requirements:
- Inline CSS only. No external CDN links, no Google Fonts, no remote anything.
- Realistic placeholder content that matches the app's actual purpose (from the brief). Not "Lorem ipsum" — real-looking names, realistic data, plausible copy.
- At least 3 sections: header/nav, main content area, footer or CTA zone.
- Show enough UI to make a real design decision. Not color swatches — an actual page layout with components.
- Assume 1200px wide viewport.

**Agent 2 — bold/expressive:**
Write a complete HTML file to `$TMPDIR/design-variant-2.html`.

Design direction: strong colors, large type, high contrast, personality. The kind of interface that makes an impression. Think Superhuman, Loom, or early Stripe's landing pages.

Same requirements as Agent 1.

**Agent 3 — data-dense/utility:**
Write a complete HTML file to `$TMPDIR/design-variant-3.html`.

Design direction: information-rich layout, compact spacing, utility-first. The kind of interface that respects the user's time and puts everything they need in view. Think GitHub, Linear's issue list, or a Bloomberg terminal that doesn't make your eyes bleed.

Same requirements as Agent 1.

**If DESIGN.md exists:** All three variants must honor its color palette and typography. Vary layout and component density only — do not override brand colors or typefaces.

Each agent must confirm the file was written before returning. If a file write fails, the agent should report the error.

## Phase 4: Screenshot Each Variant

Create the output directory first:

```bash
mkdir -p .nstack/design
```

Then screenshot each variant.

Binary mode:
```bash
$B goto "file://$TMPDIR/design-variant-1.html"
$B screenshot .nstack/design/variant-1.png

$B goto "file://$TMPDIR/design-variant-2.html"
$B screenshot .nstack/design/variant-2.png

$B goto "file://$TMPDIR/design-variant-3.html"
$B screenshot .nstack/design/variant-3.png
```

MCP mode: use `mcp__claude-in-chrome__navigate` to load each file URL, then `mcp__claude-in-chrome__computer` to take a screenshot, then save each screenshot to `.nstack/design/variant-{N}.png`.

After capturing each screenshot, immediately show it to the user with the Read tool:

```
Read .nstack/design/variant-1.png
```

Do this for each variant before asking the user to choose. They need to see all three.

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

If the user requests a blend (D): produce a 4th HTML file at `$TMPDIR/design-variant-4.html` that combines the requested elements. Screenshot it to `.nstack/design/variant-4.png`. Show it. Confirm before proceeding.

If the user wants to inspect a variant more closely (binary mode):
```bash
$B goto "file://$TMPDIR/design-variant-{N}.html"
```

If no option satisfies: go back to Phase 2 with new direction from the user.

## Phase 6: Apply to Project

Take the approved HTML variant and adapt it to the actual project tech stack.

Identify the UI layer from Phase 1:

- **React / Next.js:** Extract layout and components. Create component files with inline styles or CSS modules. Update `app/page.tsx`, `pages/index.tsx`, or the relevant entry point.
- **Vue:** Create `.vue` single-file components with scoped styles.
- **Plain HTML:** Write directly to `index.html` or the relevant template file.
- **Django / Jinja:** Adapt to `base.html` + `{% block %}` partials. Extract CSS to a static file.
- **Rails / ERB:** Adapt to `application.html.erb` + partials. Extract CSS to `application.css`.

Do not dump the entire HTML variant as one blob. Break it into the structure the project expects.

Show a summary of what changed:
- Which files were written or edited
- What was extracted (components, styles, etc.)
- Any decisions that need the user's input (e.g., where to put shared styles)

## Phase 7: Verify

Open the live result in the browser.

If a dev server is running:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || \
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || \
echo "NO_DEV_SERVER"
```

Binary mode — if dev server running:
```bash
$B goto "http://localhost:3000"
$B screenshot .nstack/design/result.png
```

Binary mode — if no dev server, open the written file:
```bash
$B goto "file://$(pwd)/index.html"
$B screenshot .nstack/design/result.png
```

MCP mode: navigate to the URL or file path, take a screenshot, save to `.nstack/design/result.png`.

Show the screenshot to the user with the Read tool.

Ask:

> Does this match what you selected? Any adjustments needed?

If adjustments are needed, make targeted edits and re-screenshot. Do not regenerate from scratch unless the user asks.

## Rules

1. Never commit files without asking first.
2. Show screenshots to the user immediately after capturing — use the Read tool on each PNG before moving on.
3. If the user says "no browser," skip Phases 4 and 5. Show the HTML file paths and ask the user to open them manually. Ask which variant they prefer, then proceed to Phase 6.
4. DESIGN.md constraints are non-negotiable. Never override its color palette or typography. If the user asks you to, clarify that DESIGN.md is a binding constraint and ask if they want to update the file first.
5. Each variant must be genuinely different — not color swaps on the same layout. Different structural approaches, different information hierarchy, different spatial rhythms.
