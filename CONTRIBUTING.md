# Contributing to nstack

nstack skills are Markdown files. Contributing means editing Markdown.
No build step, no compiler, no runtime to configure.

---

## Quick start

```bash
git clone https://github.com/nischal94/nstack.git ~/.claude/skills/nstack
```

Edit any `SKILL.md`. The change takes effect immediately in your next Claude Code session.
No restart, no rebuild, no deploy.

---

## What makes a good contribution

**High value:**
- Deeper LLM/AI security patterns in `/cso`
- New attack vectors that aren't covered (new OWASP categories, emerging AI threats)
- `/qa` patterns for specific frameworks (Next.js, FastAPI, Rails)
- `/retro` metrics that matter to solo builders
- Fixes for findings that are false positives or missed findings in practice

**Low value:**
- Adding generic security advice already covered by gstack
- Adding team-oriented workflow features (nstack is solo-builder-first)
- Adding dependencies (nstack is zero-dependency by design)
- Translating skills to other languages (one excellent example beats many mediocre ones)

---

## Skill quality bar

Before opening a PR, verify your skill change against these criteria:

### Correctness
- [ ] Every finding has a concrete exploit scenario (not "this could be a problem")
- [ ] Every false positive filter has a clear rationale
- [ ] Code examples are runnable, not illustrative pseudocode

### Conciseness
- [ ] No restating what Claude already knows
- [ ] No generic advice that applies to every codebase
- [ ] No multi-language examples of the same pattern — one great example is enough

### Discovery
- [ ] Frontmatter `description` starts with "Use when..."
- [ ] Description describes triggering conditions, not what the skill does
- [ ] Keywords a user would search for appear naturally in the text

### Compatibility
- [ ] No new mandatory dependencies introduced
- [ ] No conflicts with superpowers skill invocations
- [ ] Skill hands off to superpowers at appropriate boundaries

---

## Testing your changes

nstack has no automated test suite (no build step, no test runner). Testing is manual:

**For `/cso` changes:**
1. Run `/cso` on a real project with known vulnerabilities
2. Verify the finding appears with correct severity and exploit scenario
3. Run `/cso` on a clean project and verify no false positives

**For `/qa` changes:**
1. Run `/qa` on a running local app
2. Verify the browser flow, bug detection, and fix-then-retest cycle work end-to-end

**For `/retro` changes:**
1. Run `/retro` on a project with at least 2 weeks of git history
2. Verify stats are accurate against `git log` output

**The bar:** If you wouldn't trust the skill's output to make a real decision,
it's not ready to ship.

---

## PR process

1. Fork the repo
2. Edit the relevant `SKILL.md`
3. Test manually (see above)
4. Open a PR with:
   - What you changed and why
   - What you tested it on (real project, synthetic, etc.)
   - Any known limitations or edge cases

PRs that add features without testing evidence will be asked to show testing first.

---

## Skill file format

```markdown
---
name: skill-name
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

[skill content]
```

- `name`: letters, numbers, hyphens only
- `description`: max ~500 characters, starts with "Use when...", third person,
  describes triggering conditions only — never summarizes the skill's workflow

---

## Philosophy

Read ETHOS.md before contributing. The principles there are not aspirational —
they are the filter every contribution is measured against.

The most important ones for contributors:

**Zero noise over zero misses.** If you're adding a security check, it needs
an 8/10 confidence gate. A check that fires on every codebase teaches engineers
to ignore the output.

**Zero dependencies.** If your contribution requires installing something, it's
out of scope for nstack. Document the tradeoff and make it optional at most.

**AI-native first.** If the finding doesn't apply specifically to AI-native
projects, check if gstack already covers it. nstack's value is in the coverage
that gstack misses, not in duplicating what gstack does well.
