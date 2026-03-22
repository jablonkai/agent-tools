---
name: github-commit-pr
description: "This skill should be used when the user wants to commit changes, create a branch, push, and open a GitHub PR — or push additional commits to an existing PR. Handles issue linking with auto-close keywords, conventional commit messages, and structured PR descriptions."
category: git
risk: low
tags:
  - git
  - github
  - pull-request
  - commit
  - branch
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[<base-branch>] [--issue <number>]"
---

# github-commit-pr

## Purpose

End-to-end workflow for committing changes and creating or updating a GitHub pull request. Supports issue linking with auto-close keywords, conventional commit messages, and pushing new commits to existing PRs.

## When to use

- Committing changes and opening a new PR
- Pushing additional commits to an existing PR branch
- Creating PRs that reference and auto-close GitHub issues

## Pre-flight checks

Run these checks before any operation:

1. **Authentication:**

```bash
gh auth status
```

If `gh` is not installed, direct the user to https://cli.github.com. If not authenticated, instruct the user to run `gh auth login` and stop.

2. **Working tree status:**

```bash
git status
```

If there are no changes (nothing to commit), abort unless the user explicitly wants to create a PR from existing unpushed commits.

3. **Current branch:**

```bash
git branch --show-current
```

4. **Base branch detection:**

Determine the repository's default branch:

```bash
git remote show origin | grep 'HEAD branch' | sed 's/.*: //'
```

If `$ARGUMENTS` contains a positional argument, use it as the base branch instead. Fall back to `main` if detection fails.

## Flow detection

After pre-flight, determine the flow:

### Existing PR flow

If the current branch is NOT the base branch:

1. Check if a PR already exists for this branch:

```bash
gh pr view --json number,title,url,body 2>/dev/null
```

2. If a PR exists → go to **"Push to existing PR"** flow.
3. If no PR exists → ask the user: continue on this branch or create a new one? If continuing, skip to "New PR flow" Step 3 (no branch creation needed).

### New PR flow

If the current branch IS the base branch → proceed with full "New PR" flow (including branch creation).

## New PR flow

### Step 1: Analyze changes

```bash
git status
git diff HEAD
git log --oneline -5
```

### Step 2: Check for sensitive files

Before staging, scan `git status` output for potentially sensitive files:

- `.env`, `.env.*` files
- Files containing `secret`, `credential`, `token`, `password`, `key` in their name
- `id_rsa`, `*.pem`, `*.key`, `*.p12` files

If any are detected, **warn the user explicitly** and ask whether to exclude them. Do NOT silently stage sensitive files.

### Step 3: Propose commit message

Write a conventional commit message based on the diff:

- **Format:** `<type>: <short summary>`
- **Types:** `feat`, `fix`, `refactor`, `docs`, `style`, `chore`, `test`, `ci`
- **Summary:** imperative mood, lowercase, no period, max 72 chars
- Add a body (blank line + wrapped paragraphs) for complex changes

Present the proposed message to the user:
1. **Accept** — use as-is
2. **Edit** — user provides their own

### Step 4: Create branch

Derive a branch name from the commit message:

1. Take the summary part (after `type: `)
2. Lowercase, replace spaces with hyphens, remove special characters
3. Prefix with the type: `feat/add-dark-mode`, `fix/null-token-settings`
4. Truncate to 60 characters max

```bash
git checkout -b <branch-name>
```

If the branch already exists, append a numeric suffix (e.g., `-2`).

### Step 5: Stage and commit

```bash
git add -A
git commit -m "$(cat <<'EOF'
<type>: <summary>

<optional body>

Co-authored-by: Author Name <author@example.com>
EOF
)"
```

The `Co-authored-by` trailer follows the standard Git/GitHub format (`Name <email>`). The caller or tooling running this workflow supplies the actual name and email at runtime. Do not hardcode specific names in the skill itself.

If the commit fails due to a pre-commit hook, read the hook output, fix the issue, re-stage, and create a NEW commit (do not amend).

### Step 6: Push

```bash
git push -u origin <branch-name>
```

If push fails due to remote rejection, report the error and stop — do not force-push.

### Step 7: Build PR body

Check if the repository has a PR template:

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || \
  cat .github/pull_request_template.md 2>/dev/null || \
  cat PULL_REQUEST_TEMPLATE.md 2>/dev/null || \
  cat docs/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

If a template exists, use its structure and fill in the sections from the diff context. If no template exists, use this default structure:

```markdown
## Summary
<1-3 bullet points describing the actual changes from the diff>

## Test plan
<bulleted checklist of testing steps>
```

#### Issue linking

If `$ARGUMENTS` contains `--issue <number>`, or the user mentions an issue number, or the branch name contains an issue number:

1. Fetch the issue details:

```bash
gh issue view <number> --json title,body,labels
```

2. Add a closing keyword to the PR body at the end of the Summary section:

```markdown
## Summary
- <change description>
- <change description>

Closes #<number>
```

**Valid closing keywords** (all work the same): `Closes`, `Fixes`, `Resolves`. Use `Closes` by default. For bug fixes (commit type `fix`), use `Fixes` instead.

3. If the issue has labels, apply matching labels to the PR after creation:

```bash
gh pr edit <pr-number> --add-label "<label1>,<label2>"
```

### Step 8: Create PR

```bash
gh pr create --title "<summary>" --base "<base-branch>" --body "$(cat <<'EOF'
<PR body from Step 7>
EOF
)"
```

- **Title:** first line of commit summary without the `type:` prefix, max 70 chars
- **Base branch:** detected in pre-flight or from `$ARGUMENTS`

### Step 9: Report

Output the PR URL.

## Push to existing PR flow

When a PR already exists for the current branch:

### Step 1: Analyze new changes

```bash
git status
git diff HEAD
```

### Step 2: Check for sensitive files

Same check as New PR flow Step 2.

### Step 3: Propose commit message

Same conventions as New PR flow Step 3.

### Step 4: Stage, commit, and push

```bash
git add -A
git commit -m "$(cat <<'EOF'
<type>: <summary>

Co-authored-by: Author Name <author@example.com>
EOF
)"
git push
```

Same `Co-authored-by` rules as New PR flow Step 5.

If the commit fails due to a pre-commit hook, fix the issue and create a NEW commit (do not amend).

If push fails because the remote has new commits, pull with rebase first:

```bash
git pull --rebase origin <branch-name>
git push
```

If rebase has conflicts, stop and report — do not force-push or auto-resolve.

### Step 5: Report

Show the existing PR URL and the new commit summary:

```
Pushed to PR #<number>: <pr-title>
New commit: <type>: <summary>
URL: <pr-url>
```

Do NOT create a new PR — just push to the existing one.
Do NOT modify the PR title or body.

## Error handling

| Scenario | Detection | Action |
|----------|-----------|--------|
| `gh` not installed | `command -v gh` fails | Direct user to https://cli.github.com |
| Not authenticated | `gh auth status` exits non-zero | Instruct user to run `gh auth login` |
| Not in a git repo | `git rev-parse --show-toplevel` fails | Abort with clear message |
| No changes to commit | `git status` shows clean tree | Abort unless PR from existing commits |
| Sensitive files detected | Pattern match on `git status` output | Warn user, ask to exclude before staging |
| Pre-commit hook failure | `git commit` exits non-zero | Read output, fix issue, create new commit |
| Push rejected | `git push` exits non-zero | Report error, do not force-push |
| Branch already exists | `git checkout -b` fails | Append numeric suffix (e.g., `-2`) |
| PR creation fails | `gh pr create` exits non-zero | Report error (branch protection, permissions) |
| Remote ahead (push fails) | `git push` rejected, non-fast-forward | `git pull --rebase`, then retry push |
| Rebase conflicts | `git pull --rebase` has conflicts | Stop and report, do not auto-resolve |

## Constraints

- NEVER force-push
- NEVER amend existing commits — always create new commits
- NEVER skip pre-commit hooks (`--no-verify`)
- NEVER commit `.env`, credentials, or secrets — check before staging and warn if detected
- If any step fails, stop and report the error — do not continue blindly
- Use `git add -A` for staging (full-change commit flow), but only after the sensitive file check passes
- The PR body must reflect the actual changes from the diff, not boilerplate
- The `Co-authored-by` trailer follows the standard Git/GitHub `Name <email>` format — the caller or tooling running this workflow supplies the actual values at runtime; do not hardcode specific names
- Issue closing keywords (`Closes #N`) go in the PR body, never in the commit message
- When pushing to an existing PR, do NOT modify the PR title or body — only push the commit
