# CLAUDE.md — Agent Delegation

Be terse. Brief explanations only — just enough rationale, no padding. This
applies to Claude's own output, not to subagent output contracts.

**Activate Serena first.** On every coding task, bring up Serena before anything
else and rely on its symbolic tools — this is mandatory, not a nice-to-have.

**Delegate by default.** Hand off read-heavy or mechanical subtasks instead of
doing them inline — to a delegate CLI agent (table below) or a Claude subagent
(Agent tool). Both run in a separate context and return a summary, keeping your
main conversation free for orchestration. Subagents are especially good for
codebase mapping and research. Only work directly when delegation isn't possible
or would be slower. Claude is the orchestrator and the ONLY agent that writes to
this repo.

## Agents — when to use which

| Agent | Headless command | Use it for |
|---|---|---|
| **Antigravity CLI** | `agy -p "<prompt>"` | DEFAULT for reading: codebase exploration, log/crash analysis, doc & changelog summaries; good for agentic multi-step exploration. Paid Google subscription — generous quota. |
| **Kiro CLI** | `kiro-cli chat --no-interactive --trust-tools=fs_read "<prompt>"` | Agentic reader/explorer (Claude models). Alternate reader when `agy` is rate-limited. `--trust-tools=fs_read` keeps it read-only. |
| **OpenCode** | `opencode run "<prompt>"` | DEFAULT for generated code: test skeletons, fixtures, boilerplate, doc drafts → `/tmp/agent-out/`. Free — always auto mode, omit `-m` and let OpenCode pick the model. |
| **Codex CLI** | `codex exec "<prompt>"` | Free OpenAI tier — limited quota, use sparingly. Good for a second opinion on tricky diffs; fallback code generator when OpenCode is rate-limited. |
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

## Context hygiene (applies to Claude itself)

These are general rules across stacks — Android/Gradle, Flutter, React
Native, web/Node, macOS/iOS/Xcode, etc. — not tied to any one project type.

1. **Never read build output or generated code.** Keep `build/`, `.gradle/`,
   `node_modules/`, `dist/`, `.next/`, `.dart_tool/`, `Pods/`, `DerivedData/`,
   and generated sources (KSP, Room schema, `BuildConfig`, `R`, `*.g.dart`,
   protobuf/GraphQL/OpenAPI codegen, etc.) out of context. Map and research
   from source only.
2. **Build-tool output is the silent context killer.** Run quiet
   (`gradle --console=plain`, `npm run --silent`, `flutter ... | tail`,
   `xcodebuild -quiet`) and `grep`/`rg` the output for the relevant lines —
   never dump the full log. Same for linter/analyzer reports (detekt,
   ktlint, ESLint, `flutter analyze`, SwiftLint): filter, don't paste it all.
3. **Never paste a full dependency tree** (`:app:dependencies`, `npm ls`,
   `flutter pub deps`, `pod` graphs) — they're enormous. Grep for the one
   dependency you care about.

## Output contract — append to every delegated prompt

```
Max 40 lines of markdown. Use file:line references. No preamble.
If uncertain, say UNCERTAIN and stop.
```

## Examples

Each agent's invocation is in the table; the patterns worth noting:

```bash
# Append the output contract to read/explore prompts
agy -p "How does feature X flow through the modules of this repo? <contract>"

# Pipe logs in rather than reading them into Claude's context
tail -n 2000 build.log | agy -p "Root-cause error? Max 15 lines. <contract>"

# Generated code goes to /tmp/agent-out/ for Claude to review, never inline
opencode run "Unit test skeleton for: <FILE>" > /tmp/agent-out/foo-test
```

@RTK.md