# CLAUDE.md — Agent Delegation

**Delegate by default.** Whenever a task can reasonably be handed off, offload
it — either to a delegate CLI agent (see the table below) or to one of Claude's
own subagents (via the Agent tool) — instead of doing it inline. This keeps
Claude's context free for orchestration and integration. Only do work directly
when delegation isn't possible or would be slower than just doing it.

Offload read-heavy or mechanical subtasks to delegate CLI agents to save
Claude context. Prefer the paid Google (Antigravity) and OpenAI (Codex)
subscriptions — their quotas are generous; the free-tier agents are
fallbacks. Claude is the orchestrator and the ONLY agent that writes
to this repo.

## Agents — when to use which

| Agent | Headless command | Use it for |
|---|---|---|
| **Antigravity CLI** | `agy -p "<prompt>"` | DEFAULT for reading: codebase exploration, log/crash analysis, doc & changelog summaries; good for agentic multi-step exploration. Paid Google subscription — generous quota. |
| **Kiro CLI** | `kiro-cli chat --no-interactive --trust-tools=fs_read "<prompt>"` | Agentic reader/explorer (Claude models). Alternate reader when `agy` is rate-limited. `--trust-tools=fs_read` keeps it read-only. |
| **Codex CLI** | `codex exec "<prompt>"` | DEFAULT for generated code: test skeletons, fixtures, boilerplate, doc drafts → `/tmp/agent-out/`. Also second opinion on tricky diffs. Paid OpenAI subscription. |
| **OpenCode** | `opencode run "<prompt>"` | Free FALLBACK code generator when Codex is rate-limited. Always auto mode — omit `-m`, let OpenCode pick the model. |
| **Kilo Code CLI** | `kilo run -m kilo-auto/free "<prompt>"` | Same as OpenCode (it's OpenCode-based). Second free fallback. Always auto mode — `kilo-auto/free` auto-routes to the best available free model. |
| **Cursor CLI** | `cursor-agent -p "<prompt>" --output-format text` | Free FALLBACK reader when the Google agents are rate-limited. Hobby free quota is limited — not for routine bulk reads. ⚠ `-p` mode has write+bash access: only send read-style prompts and state "Do NOT modify files". |
| **Copilot CLI** | `copilot -p "<prompt>" -s --deny-tool write --deny-tool shell` | GitHub-context questions: issues, PRs, Actions runs via its built-in GitHub MCP. Copilot Free credit quota is small — sparingly. |

Production code, build/CI/release configuration, architecture decisions → **Claude only**.

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
# Exploration (Antigravity)
agy -p "How does feature X flow through the modules of this repo? <contract>"

# Log analysis (Antigravity)
tail -n 2000 build.log | agy -p "Root-cause error? Max 15 lines. <contract>"

# Long-file analysis (Antigravity)
agy -p "Summarize responsibilities and risks in this 3000-line file: \
  <FILE>. <contract>"

# Alternate reader when Antigravity is rate-limited (Kiro, read-only)
kiro-cli chat --no-interactive --trust-tools=fs_read \
  "Map the module dependencies of this repo. <contract>"

# Test scaffolding (Codex)
codex exec "Unit test skeleton (project's test framework) for: <FILE>" \
  > /tmp/agent-out/foo-test

# Second opinion (Codex)
git diff HEAD~1 | codex exec \
  "Review for bugs and common pitfalls (concurrency, edge cases). Max 20 lines."

# Fallback scaffolding when Codex is rate-limited (OpenCode, auto mode)
opencode run \
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