---
name: github-do-issue
description: "This skill should be used when the user assigns a GitHub issue to be worked on. Fetches issue details, understands requirements, implements the solution, and runs verification — but does NOT commit, push, or create a PR automatically. The user decides when to commit."
category: development-workflow
risk: low
tags:
  - github
  - issues
  - development
  - workflow
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
argument-hint: "<issue-number-or-url>"
---

# github-do-issue

## Purpose

Structured workflow for implementing a GitHub issue in any project. Fetch the issue, understand the requirements, plan the approach, implement the solution, and verify it — then stop and let the user review before any git operations happen.

## When to use

- User says "work on issue #N", "do #N", "implement #N", or similar
- User provides a GitHub issue URL
- User references an issue number and asks to implement it

## Prerequisites

Before starting, verify the environment:

1. **Authentication:**

```bash
gh auth status
```

If `gh` is not installed, direct the user to https://cli.github.com. If not authenticated, instruct the user to run `gh auth login`.

2. **Repository context:**

```bash
git rev-parse --show-toplevel
```

If not in a git repository, abort with a clear message.

## Workflow

### Step 1: Fetch issue details

Parse the issue number from `$ARGUMENTS`:

- `42` or `#42` → use directly
- `https://github.com/owner/repo/issues/42` → extract `42` and the `owner/repo` from the URL. If the URL points to a different repo than the current working directory, warn the user and ask whether to proceed (the implementation will happen in the current repo, but the issue context comes from the referenced repo).

Fetch the issue:

```bash
gh issue view "$ISSUE_NUMBER" ${ISSUE_REPO:+--repo "$ISSUE_REPO"} --json number,title,body,labels,assignees,milestone,state,comments
```

`ISSUE_REPO` is set to `owner/repo` only when the input was a URL pointing to a different repository; otherwise it is left unset and `gh` defaults to the current repository.

If the command fails (issue not found, permission denied), report the error and stop.

**Check issue state:** If the issue is already closed, warn the user:

```
Issue #42 is already closed. Do you still want to implement it?
```

Proceed only if the user confirms.

Display a summary to the user (the `comments` field is included in the fetch above — they often contain clarifications, decisions, or updated requirements):

```
Issue #42: <title>
State: open | Labels: enhancement
---
<issue body, trimmed to key requirements>
<key points from comments, if any>
```

### Step 2: Understand requirements

Extract from the issue body and comments:

- **What needs to change** — the feature, fix, or improvement
- **Acceptance criteria** — checkboxes or explicit requirements
- **Scope boundaries** — what is NOT in scope (if mentioned)
- **Related context** — linked issues, mentioned files, or referenced PRs

If the issue is unclear or missing critical details, ask the user for clarification before proceeding.

### Step 3: Plan the approach

Before writing any code:

1. Identify which files need to be created or modified
2. Consider the project's existing patterns and conventions — read project documentation (README.md, CLAUDE.md, AGENTS.md, CODEX.md, CONTRIBUTING.md, or similar), check existing code for patterns, review configuration files
3. Present a brief implementation plan to the user:

```
Implementation plan for #42:
1. <specific change>
2. <specific change>
3. <specific change>
```

4. If the plan reveals the issue is larger than expected, tell the user and suggest breaking it into smaller steps or separate issues.

Wait for the user to approve or adjust the plan.

### Step 4: Implement

Execute the approved plan:

- Follow existing code conventions and patterns discovered in Step 3
- Write clean, focused changes — only what the issue requires, no scope creep
- If the project uses i18n, add translation keys for new user-visible strings
- If a sub-task turns out to be more complex than planned, pause and inform the user rather than expanding scope silently

### Step 5: Verify

After implementation, run the project's verification checks. Detect which tools are available and run the appropriate ones:

- **TypeScript/JavaScript:** `npx tsc --noEmit`, `npm test`, `npm run lint`
- **Rust:** `cargo check`, `cargo test`
- **Python:** `python -m pytest`, `mypy .`, `ruff check .`
- **Go:** `go build ./...`, `go test ./...`
- **Android (Kotlin/Java):** `./gradlew build`, `./gradlew test`, `./gradlew lint`
- **Flutter/Dart:** `flutter analyze`, `flutter test`
- **Other:** check `package.json` scripts, `Makefile`, CI config, or `build.gradle` for available checks

If no verification commands are found, inform the user and suggest they run their own checks manually.

Run at minimum the type checker / compiler. Fix any errors before proceeding.

### Step 6: Report and stop

Present a summary of all changes made:

```
Done — Issue #<number>: <title>

Files modified:
- <path> (new)
- <path> (modified)

Verification:
- Type check: clean
- Tests: passed

Ready for review.
```

**STOP HERE.** Do not commit, push, create a branch, or create a PR. The user decides what to do next.

## Error handling

| Scenario | Detection | Action |
|----------|-----------|--------|
| `gh` not installed | `command -v gh` fails | Direct user to https://cli.github.com |
| Not authenticated | `gh auth status` exits non-zero | Instruct user to run `gh auth login` |
| Not in a git repo | `git rev-parse` fails | Abort with clear message |
| Issue not found | `gh issue view` exits non-zero | Verify issue number and repo |
| Permission denied | `gh` returns 403/404 | Check repo access and auth scopes |
| Issue already closed | `state` field is `CLOSED` | Warn user, proceed only if confirmed |
| Issue from different repo | URL doesn't match current repo | Warn user, ask whether to proceed |
| Scope larger than expected | Discovered during planning/implementation | Pause, inform user, suggest splitting |
| Verification tools not found | Commands not available | Inform user, suggest manual verification |

## Critical constraints

- **NEVER commit** after completing the implementation — the user must review first
- **NEVER push** to any remote
- **NEVER create a PR** automatically
- **NEVER create a branch** — stay on the current branch; branch creation is the user's responsibility
- Do not modify files outside the scope of the issue
- Ask for clarification rather than guessing when requirements are ambiguous
- If implementation reveals unexpected complexity, pause and inform the user rather than expanding scope
