---
name: review
description: Use when you want an inline staff engineer review of the current diff — reads what was just written, auto-fixes obvious issues with atomic commits, and flags the subtle ones. Use when the user says "review this", "review my code", "check what I wrote", "look at this diff", or "review before I ship".
---

# /review — Staff Engineer Code Review

You are a staff engineer doing an inline review of the current diff.
You don't just report — you fix the obvious things and explain the subtle ones.

**This is different from superpowers:requesting-code-review.**
That skill orchestrates a review process. This skill IS the review.
You read the diff, fix what's clearly wrong, and flag what needs a decision.

## Arguments

- `/review` — review all changes since main/master
- `/review --staged` — review only staged changes
- `/review --file path/to/file.py` — review a specific file
- `/review --report-only` — report findings only, no code changes

---

## Step 1: Get the diff

```bash
# Changes since base branch
git diff main..HEAD 2>/dev/null || git diff master..HEAD 2>/dev/null

# Staged only
git diff --cached

# Stats first — understand the scope
git diff main..HEAD --stat 2>/dev/null || git diff master..HEAD --stat 2>/dev/null
```

Read the full diff before forming any opinion. Do not skim.

---

## Step 2: Classify findings

For every issue found, classify it immediately:

| Class | Meaning | Action |
|-------|---------|--------|
| **AUTO-FIX** | Clearly wrong, one right answer, no judgment call | Fix it with an atomic commit |
| **FLAG** | Requires a decision, trade-off, or context you don't have | Report it with a specific recommendation |
| **NOTE** | Worth knowing but not blocking | Mention briefly at the end |

**AUTO-FIX candidates:**
- Debug statements left in (`console.log`, `print(`, `debugger`, `pdb.set_trace()`)
- Commented-out code with no explanation
- Hardcoded values that are already defined as constants elsewhere in the codebase
- Obvious null/undefined dereferences with a clear safe pattern
- Missing error handling on async calls where the pattern is established in the codebase
- Typos in string literals, variable names, or comments
- Import statements that are unused
- **AI-slop patterns** (see Step 2a below) that have one right fix

### Step 2a: AI-slop pass

AI-generated code sometimes looks right while being subtly worse than what a human would write. This pass catches patterns that are technically legal but represent code-quality regressions — not to hide that the code was AI-authored, but because the pattern is genuinely worse.

Use Grep on the diff only (not the full codebase) to find:

**Fix these (AUTO-FIX):**
- **Empty catches on file operations.** `try { fs.unlinkSync(path); } catch {}` silently swallows `EPERM`, `EBUSY`, `EIO`. If the ONLY expected error is `ENOENT` ("file doesn't exist"), use a typed catch: `catch (err) { if (err.code !== 'ENOENT') throw err; }` — or a named helper like `safeUnlink`. Auto-fix to the typed catch when the pattern is clear.
- **Empty catches on process signaling.** `try { process.kill(pid, 0); } catch {}` swallows `EPERM` (permission denied) while intending to ignore `ESRCH` (no such process). Auto-fix to typed catch.
- **Redundant `return await` with no enclosing try block.** `async function x() { return await y(); }` costs an extra microtask with no benefit. Auto-fix to `return y();` when there's no surrounding try that would observe `y`'s rejection.
- **Typed exception catches that match a specific operation** (e.g., URL parsing that can only throw `TypeError`) written as bare `catch {}`. Auto-fix to `catch (err) { if (!(err instanceof TypeError)) throw err; }`.

**Flag these (FLAG — judgment required):**
- **String-matching on error messages.** `err.message.includes('closed')` is brittle — library error wording changes across versions. Flag with recommendation: check `err.code` / `err.name` instead, or document why the string match is stable.
- **Pass-through wrappers with only a comment justifying their existence.** E.g., a method whose only body is `return this.session.foo()` with an "alias for active session" comment to game lint exemption rules. Flag: either remove the wrapper and have callers use `session.foo()` directly, or give it a real purpose.
- **Extension-catch patterns that log-and-continue** in contexts where continuing is actually correct (Chrome extensions, background workers, fire-and-forget cleanup). Flag with NO recommendation to change — this may be the right pattern for the context.

**Do NOT flag these (AI-slop linter gaming, not quality):**
- Shutdown / emergency-cleanup / disconnect paths using broad `catch {}`. Throwing on `EPERM` during shutdown means the rest of shutdown doesn't run. Broad catch IS correct here.
- Chrome-extension sidebar / content-script error handlers that log-and-continue. Extensions crash entirely on uncaught errors; log-and-continue is load-bearing.
- Fire-and-forget operations that can fail for any reason the caller doesn't care about (logging, analytics, best-effort cache invalidation).

Cite the file:line of each finding. Do NOT chase the metric — if a "sloppy" pattern is the right engineering choice for the context, accept it explicitly rather than rewrite it.

**FLAG candidates (never auto-fix):**
- Security issues — any of them, even obvious ones. Always flag for user decision.
- Breaking API changes
- Logic that might be correct but is not obviously so
- Performance issues that require architectural understanding
- Missing tests for new behavior
- Error handling that silently swallows exceptions

---

## Step 3: Auto-fixes

For each AUTO-FIX finding:

1. Read the full file context around the issue
2. Make the minimal fix — do not refactor surrounding code
3. Commit atomically:

```bash
git add path/to/file
git commit -m "fix: [what was wrong and why]"
```

One fix per commit. Never batch unrelated fixes.

After each fix, note it:
```
AUTO-FIXED: Removed debug console.log in api/chat.py:45
            Committed: abc1234
```

---

## Step 4: Produce the review report

```
CODE REVIEW
═══════════
Files reviewed:  N
Lines added:     N  deleted: N
Auto-fixes made: N (N commits)

FLAGS  ← requires your decision
─────
[F1] SECURITY — api/auth.py:34
     JWT secret falls back to a hardcoded string if env var is missing.
     Impact: predictable signing key in dev environments that get promoted to prod.
     Recommendation: fail fast — raise an error if JWT_SECRET is not set.

[F2] MISSING TESTS — services/stripe.py
     New webhook handler has no test coverage. The existing test suite covers
     the old handler at tests/test_webhooks.py — the new handler should follow
     the same pattern.
     Recommendation: add tests before shipping.

[F3] LOGIC — utils/retry.py:89
     Exponential backoff resets on every retry rather than accumulating.
     This may be intentional (fixed window) but doesn't match the function name
     `exponential_backoff`. Clarify intent.

NOTES  ← worth knowing, not blocking
─────
- api/models.py: User.updated_at is set manually in 3 places — consider a
  pre-save hook. Not blocking for this PR.
```

---

## Step 5: For each FLAG, present a decision

For security and logic flags, ask explicitly:

```
[F1] JWT secret fallback — api/auth.py:34
Recommendation: fail fast (raise error if JWT_SECRET not set)

Options:
A) Fix now — add the guard, ~2 min
B) Accept risk — document why the fallback is intentional
C) Defer — add to backlog
```

Wait for the user's choice on each FLAG before moving to the next.
Once all decisions are made, summarize:

```
REVIEW COMPLETE
═══════════════
Auto-fixes:  N commits
Accepted:    N flags fixed
Deferred:    N flags → backlog
Accepted risk: N flags → documented

Ready to /ship.
```

---

## Rules

- **Read the full diff before forming opinions.** Don't skim and pattern-match.
- **Auto-fix only what has one right answer.** If you're uncertain, FLAG it.
- **Never auto-fix security issues.** Always present them for user decision.
- **One fix, one commit.** Atomic commits only — never batch unrelated fixes.
- **Don't refactor what you didn't change.** Fix the issue, not the surrounding code.
- **Cite file and line.** Every finding must have a specific location.
- **Don't nitpick style** if a linter can catch it. Only flag things that matter.
