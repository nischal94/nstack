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

**For `/premise` changes:**
1. Run `/premise "add X"` on a feature that clearly shouldn't be built — verify CHALLENGED or DEFER verdict
2. Run `/premise "add X"` on a feature that clearly should — verify CONFIRMED verdict
3. Verify challenges run one at a time, not batched

**For `/investigate` changes:**
1. Run on a project with a known regression (introduce one if needed)
2. Verify the hypothesis names a specific file and line with confidence rating
3. Verify it hands off to superpowers:systematic-debugging

**For `/review` changes:**
1. Introduce obvious issues (debug statement, unused import) and verify auto-fix commits
2. Introduce a security issue and verify it flags for decision, not auto-fixes
3. Verify no changes are made to files outside the diff

**For `/autoplan` changes:**
1. Run on a plan with a known gap — verify BLOCKED verdict with specific gap named
2. Run on a solid plan — verify READY verdict
3. Verify AI-native checks fire on plans involving LLM calls

**For `/evals` changes:**
1. Run `--create` on a project with at least one LLM call site
2. Verify eval cases cover happy path, adversarial, and edge cases
3. Run `--compare` with two prompt variants and verify delta is correctly calculated

**For `/migrate` changes:**
1. Run on a migration with a DROP COLUMN — verify HIGH risk flagged
2. Run on an additive migration (ADD COLUMN nullable) — verify LOW risk
3. Verify dry-run runs before any apply step

**For `/context` changes:**
1. Introduce a stale file reference in CLAUDE.md — verify it's caught
2. Introduce a contradiction between two rules files — verify it's caught
3. Verify no memory files are modified without confirmation

**For `/careful`, `/freeze`, `/guard`, `/unfreeze` changes:**
1. Run `/careful` and attempt a destructive command — verify confirmation prompt
2. Run `/freeze src/` and attempt an edit outside src/ — verify refusal
3. Run `/guard` and verify both protections are active simultaneously
4. Run `/unfreeze` and verify edits outside the locked directory are permitted again

**For `/ship` and `/land` changes:**
1. Run `/ship` with a failing test — verify it stops at the test step
2. Run `/land` with a PR number and verify CI wait, merge, deploy detection, health check sequence
3. Verify `/land` offers rollback if health check fails

**For `/council` changes:**
1. Run with a clear architecture question — verify triad auto-selection is correct
2. Verify Round 1 runs in parallel, Round 2 sequential, Round 3 parallel-except-Socrates
3. Introduce a deflecting response from a member — verify coordinator intervention fires

**For `/document-release` changes:**
1. Run on a project with at least one git tag — verify commits since that tag are grouped correctly
2. Verify semver bump determination (feat → MINOR, fix → PATCH)
3. Verify it never tags without explicit confirmation

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
