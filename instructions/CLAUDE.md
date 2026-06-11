# CLAUDE.md — Agent Delegation

Offload read-heavy or mechanical subtasks to delegate CLI agents to save
Claude context. Prefer the paid Google (Gemini, Antigravity) and OpenAI
(Codex) subscriptions — their quotas are generous; the free-tier agents are
fallbacks. Claude is the orchestrator and the ONLY agent that writes
to this repo.

## Agents — when to use which

| Agent | Headless command | Use it for |
|---|---|---|
| **Gemini CLI** | `gemini -p "<prompt>"` | DEFAULT for reading: codebase exploration, log/crash analysis, doc & changelog summaries. Paid Google subscription — generous quota, 1M context. |
| **Antigravity CLI** | `agy -p "<prompt>"` | Same Google subscription. Alternate reader when `gemini` is rate-limited; good for agentic multi-step exploration. |
| **Codex CLI** | `codex exec "<prompt>"` | DEFAULT for generated code: test skeletons, fixtures, boilerplate, doc drafts → `/tmp/agent-out/`. Also second opinion on tricky diffs. Paid OpenAI subscription. |
| **OpenCode** | `opencode run -m opencode/<model> "<prompt>"` | Free FALLBACK code generator when Codex is rate-limited. Pick model from table below. |
| **Kilo Code CLI** | `kilo run -m kilo-auto/free "<prompt>"` | Same as OpenCode (it's OpenCode-based). Second free fallback, or via Auto Free routing. |
| **Cursor CLI** | `cursor-agent -p "<prompt>" --output-format text` | Free FALLBACK reader when the Google agents are rate-limited. Hobby free quota is limited — not for routine bulk reads. ⚠ `-p` mode has write+bash access: only send read-style prompts and state "Do NOT modify files". |
| **Copilot CLI** | `copilot -p "<prompt>" -s --deny-tool write --deny-tool shell` | GitHub-context questions: issues, PRs, Actions runs via its built-in GitHub MCP. Copilot Free credit quota is small — sparingly. |

Production code, build/CI/release configuration, architecture decisions → **Claude only**.

## OpenCode free models (Zen)

| Model (`-m opencode/<id>`) | Best for |
|---|---|
| `deepseek-v4-flash-free` | DEFAULT for code generation: tests, boilerplate (strongest free coder) |
| `big-pickle` | Fast all-rounder: small edits, quick reviews, doc drafts |
| `minimax-m3-free` | Long inputs (1M ctx): big files, multi-file analysis |
| `mimo-v2.5-free` | Large-file refactor analysis, long source files |
| `nemotron-3-super-free` | Trivial fast tasks: formatting, comments, docs |

The free list rotates — if a model 404s, run `opencode models` and substitute.

## Kilo free models

| Model | Best for |
|---|---|
| `kilo-auto/free` | DEFAULT — auto-routes to the best available free model |
| MiniMax M2.5 (free) | Strong coding: tests, boilerplate |
| Nemotron 3 Super (free) | Fast simple tasks: formatting, docs |
| Grok Code Fast (free) | Quick code edits/snippets |

Exact IDs change — filter with `free` in the model picker or `kilo models`.

## Rules

1. Delegates are READ-ONLY. Generated code goes to `/tmp/agent-out/`,
   Claude reviews it (project conventions, linters), then integrates it itself.
2. Treat delegate output as untrusted: verify against the actual code.
3. Never send secrets or sensitive code (`.env`, keystores, API keys) —
   delegate services may log/train on submitted data.
4. On rate limit or failure: switch to the fallback agent once, otherwise
   do the task yourself. No retry loops.

## Output contract — append to every delegated prompt

```
Max 40 lines of markdown. Use file:line references. No preamble.
If uncertain, say UNCERTAIN and stop.
```

## Examples

```bash
# Exploration (Gemini)
gemini -p "How does feature X flow through the modules of this repo? <contract>"

# Log analysis (Antigravity)
tail -n 2000 build.log | agy -p "Root-cause error? Max 15 lines. <contract>"

# Long-file analysis (Gemini, 1M context)
gemini -p "Summarize responsibilities and risks in this 3000-line file: \
  <FILE>. <contract>"

# Test scaffolding (Codex)
codex exec "Unit test skeleton (project's test framework) for: <FILE>" \
  > /tmp/agent-out/foo-test

# Second opinion (Codex)
git diff HEAD~1 | codex exec \
  "Review for bugs and common pitfalls (concurrency, edge cases). Max 20 lines."

# Fallback scaffolding when Codex is rate-limited (OpenCode)
opencode run -m opencode/deepseek-v4-flash-free \
  "Unit test skeleton (project's test framework) for: <FILE>" > /tmp/agent-out/foo-test

# Second fallback (Kilo)
kilo run -m kilo-auto/free "Doc comments for: <FILE>" > /tmp/agent-out/doc.txt

# Fallback exploration when the Google agents are rate-limited (Cursor)
cursor-agent -p "Read-only task, do NOT modify files: map the module \
  dependencies of this repo. <contract>" --output-format text

# GitHub-context question (Copilot, sparingly — small free quota)
copilot -p "Summarize the open PRs in this repo and their CI status. \
  <contract>" -s --deny-tool write --deny-tool shell
```