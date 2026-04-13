# Detection Patterns

Canonical reference for regex and string patterns used by multiple nstack skills.
Factored out to avoid duplication and drift. Update here; every skill that
references a section picks up the change on the next invocation.

Consumers today: `/cso` Phase 2 (Secrets Archaeology), `/cso` Phase 7a (prompt injection detection), `/cso` Phase 8a (skill supply chain), `/cso` Phase 8b (agent tool descriptions), `/mcp-audit` Phase 5 (tool-description scan) and Phase 6 (config hygiene), `/compliance-scaffold` (credential access surface analysis), `/review` Step 2a (AI-slop pass).

Future consumers: any new skill that audits for secrets, prompt injection, or credential access.

---

## § Secrets

Used by: `/cso` Phase 2 (Secrets Archaeology), `/cso` Phase 8a (skill supply chain — key access), `/mcp-audit` Phase 6 (config hygiene).

### Known key prefixes (high-signal)

| Prefix | Issuer |
|---|---|
| `sk-ant-` | Anthropic API keys |
| `sk-` | OpenAI keys, Stripe `sk_live_`, and many SaaS |
| `AKIA`, `AGPA`, `AIDA`, `AROA`, `AIPA`, `ANPA`, `ANVA`, `ASIA` | AWS access key ID (various principal types) |
| `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_` | GitHub classic + fine-grained personal access tokens |
| `xoxb-`, `xoxp-`, `xapp-`, `xoxa-`, `xoxr-` | Slack bot/user/app tokens |
| `glpat-` | GitLab personal access tokens |
| `AIza` | Google API keys (Maps, GCP, etc.) |
| `ya29.` | Google OAuth access tokens |
| `npm_` | npm access tokens |
| `dop_v1_` | DigitalOcean personal access tokens |
| `shpat_`, `shpca_`, `shppa_`, `shpss_` | Shopify tokens |
| `sq0atp-`, `sq0csp-` | Square tokens |
| `SG.`, `sgp_` | SendGrid API keys (legacy + new) |
| `hf_` | Hugging Face tokens |
| `pplx-` | Perplexity tokens |
| `sk_live_`, `pk_live_`, `rk_live_` | Stripe keys (live) |

### Generic credential assignment patterns

- `password\s*[=:]\s*["'][^"']+["']`
- `api[_-]?key\s*[=:]\s*["'][^"']+["']`
- `secret\s*[=:]\s*["'][^"']+["']`
- `token\s*[=:]\s*["'][^"']+["']`
- `private[_-]?key\s*[=:]`
- `-----BEGIN [A-Z ]+PRIVATE KEY-----`

### Git history commands

```bash
git log -p --all -S "AKIA" --diff-filter=A 2>/dev/null
git log -p --all -S "sk-" --diff-filter=A 2>/dev/null
git log -p --all -G "ghp_|gho_|github_pat_" 2>/dev/null
git log -p --all -G "xoxb-|xoxp-|xapp-" 2>/dev/null
git log -p --all -G "password|secret|token|api_key" -- "*.env" "*.yml" "*.json" "*.conf" 2>/dev/null
```

### Tracked `.env` files

```bash
git ls-files '*.env' '.env.*' 2>/dev/null | grep -v '.example\|.sample\|.template'
grep -q "^\.env$\|^\.env\.\*" .gitignore 2>/dev/null && echo ".env IS gitignored" || echo "WARNING: .env NOT in .gitignore"
```

### False-positive filters

Apply these before reporting any secret finding:

- Exclude placeholders: `your_`, `changeme`, `TODO`, `<REPLACE_ME>`, `xxx`, `REDACTED`, `example`, `foo`, `bar`
- Exclude test fixtures unless the same value appears in non-test code
- Exclude `.env.example`, `.env.sample`, `.env.template` — these are documentation
- Rotated secrets still flagged (they were exposed at commit time; the window of exposure matters)
- Short strings that match a prefix but look synthetic (e.g. `sk-test123`, `AKIAXXXXXXXXXXXXXXXX`)

---

## § Prompt injection triggers

Used by: `/cso` Phase 7a (LLM prompt injection), `/cso` Phase 8a (skill file content), `/cso` Phase 7c (RAG retrieval sanitization), `/mcp-audit` Phase 5 (MCP tool descriptions).

Phrases that attempt to override, hijack, or exfiltrate model instructions:

**Instruction override:**
- `ignore (all )?previous (instructions|prompts|directives)`
- `disregard (your |the )?(previous )?(instructions|guidelines|rules)`
- `forget (your |the )?(previous )?instructions`
- `you are now (a|an)`
- `new instructions:` / `updated instructions:`
- `system override` / `override mode`
- `from now on,?`

**Token-boundary spoofing (model format injection):**
- `<\|endoftext\|>`, `<\|system\|>`, `<\|user\|>`, `<\|assistant\|>`, `<\|im_start\|>`, `<\|im_end\|>`
- `[INST]`, `[/INST]`, `<s>`, `</s>` — Llama/Mistral instruction tags
- `\nASSISTANT:`, `\nHuman:`, `\nSystem:` at the start of a user-controlled string

**Context exfiltration:**
- Instructions requesting the model output: "your system prompt", "your instructions", "tools you have access to", "what you were told"
- Instructions requesting raw conversation state, hidden context, or tool definitions

### False-positive filters

- User content in the user-message position of an LLM conversation is NOT prompt injection — it's the intended position for user text. Only flag when user content enters the system prompt, tool schemas, function definitions, or RAG retrieval context.
- Documentation files describing prompt injection as a concept (e.g., a security skill's SKILL.md that mentions these phrases to teach detection) are NOT findings — distinguish descriptive mentions from executable injection attempts.

---

## § Credential access patterns

Used by: `/cso` Phase 8a (skills/MCP servers reading env), `/mcp-audit` Phase 3 (MCP permission scope).

**Env var names for common credentials:**
- `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `GEMINI_API_KEY`, `COHERE_API_KEY`, `HUGGINGFACE_API_KEY`
- `GITHUB_TOKEN`, `GH_TOKEN`, `GITLAB_TOKEN`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- `STRIPE_SECRET_KEY`, `STRIPE_API_KEY`, `STRIPE_WEBHOOK_SECRET`
- `DATABASE_URL`, `DB_PASSWORD`, `REDIS_URL` (connection strings often contain creds)
- Generic: `.*_TOKEN`, `.*_SECRET`, `.*_KEY`, `.*_PASSWORD`, `.*_CREDENTIALS`

**Runtime access patterns:**
- Node: `process\.env\.[A-Z_]+`
- Python: `os\.environ\[`, `os\.getenv\(`
- Ruby: `ENV\[`
- Go: `os\.Getenv\(`
- PHP/C: `getenv\(`
- Deno: `Deno\.env\.get\(`

---

## How skills reference this file

Inside a SKILL.md, instruct Claude to read this file and apply the relevant section. Example:

> Read `docs/detection-patterns.md` § Secrets and apply those patterns to git history and currently tracked files in this repo.

**Do not duplicate the patterns inline.** Drift between copies is how new key formats get missed. If a new pattern is needed, add it here; all consuming skills pick it up automatically.

---

## Contribution rules

- A pattern added to this file must have at least one skill that uses it — not speculative coverage.
- Each pattern needs a clear issuer or attack vector attribution.
- When adding FP filters, cite a concrete false-positive case you've observed (not theoretical).
- Deprecating a pattern requires checking every consuming skill first and updating them in the same commit.
