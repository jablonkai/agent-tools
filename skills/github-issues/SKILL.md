---
name: github-issues
description: "This skill should be used when the user wants to create, manage, or triage GitHub issues. Provides standardized issue templates with required sections, enforces GitHub default labels, and ensures consistent issue quality across any project."
category: project-management
risk: safe
tags:
  - github
  - issues
  - labels
  - project-management
  - triage
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[create <title> | view <number> | close <number> [reason] | comment <number> <text> | label <number> <label> [--remove] | triage | list [--label <label>]]"
---

# github-issues

## Purpose

Standardize GitHub issue creation and management across any project. Ensure every issue has a clear structure, proper labels, and actionable content. Guide the user through creating well-formed issues and applying GitHub's default label taxonomy consistently.

## Prerequisites

Before any operation, verify the environment:

1. **Check `gh` CLI is available and authenticated:**

```bash
gh auth status
```

If not installed, direct the user to https://cli.github.com. If not authenticated, instruct the user to run `gh auth login`.

2. **Detect repository context:**

```bash
git remote get-url origin
```

Parse `owner` and `repo` from the remote URL. Supports both formats:
- SSH: `git@github.com:owner/repo.git`
- HTTPS: `https://github.com/owner/repo.git`

Store the result as `REPO="owner/repo"`. If not in a git repository or no remote is configured, ask the user to specify `owner/repo` manually and store it as `REPO`.

Perform this parsing step **before** running any `gh issue` or `gh label` commands. When constructing `gh issue` or `gh label` commands, include `-R "$REPO"` so they always target the correct repository, regardless of whether the user is inside a local clone.

## When to use

- Creating a new GitHub issue
- Viewing issue details
- Closing issues with explanation
- Commenting on existing issues
- Triaging or labeling existing issues
- Listing open issues with their labels

## Issue structure

Every new issue MUST follow this structure:

### Title

- Start with a short, descriptive summary (max 72 characters)
- Use imperative mood: "Add ...", "Fix ...", "Update ...", "Remove ..."
- Do NOT prefix with type (no "Bug: ..." or "[Feature] ...") — labels handle categorization

### Body

Choose the template that matches the issue type:

#### Enhancement / Feature template

```markdown
## Summary
<1-3 sentences describing what needs to happen and why>

## Proposed Solution
<Detailed description of the implementation approach. Include:>
- Affected files or modules (with paths where known)
- Sub-sections for distinct layers (e.g., ### Backend, ### Frontend)
- Code snippets or API signatures if relevant

## Additional context
<Links, screenshots, related issues, or implementation notes>
```

#### Bug template

```markdown
## Summary
<1-3 sentences describing the bug and its impact>

## Current behavior
<What happens now — include error messages, stack traces, or logs>

## Expected behavior
<What should happen instead>

## Steps to reproduce
1. Step one
2. Step two
3. ...

## Proposed Solution
<Fix approach — which file/function to change and how>

## Additional context
<Links, screenshots, related issues>
```

**Rules:**
- "Summary" is always required — this is the primary section explaining what and why
- For bugs: "Current behavior", "Expected behavior", and "Steps to reproduce" are required
- "Proposed Solution" is strongly encouraged — include specific file paths, module names, and implementation details when known
- Use sub-headings (### Backend, ### Frontend, ### Flow) within "Proposed Solution" for complex changes touching multiple layers
- "Additional context" is optional but encouraged
- Remove unused sections rather than leaving them empty
- Reference concrete file paths and function/type names to make issues actionable

## GitHub default labels

Always apply at least ONE type label and optionally a priority/status label. Use GitHub's built-in default labels:

### Type labels (apply exactly one)

| Label | When to use |
|-------|-------------|
| `bug` | Something is broken or not working as expected |
| `enhancement` | New feature or improvement to existing functionality |
| `documentation` | Documentation needs to be added or updated |
| `question` | Needs clarification or discussion before action |

### Status labels (apply as needed)

| Label | When to use |
|-------|-------------|
| `duplicate` | Issue already exists — link the original and close |
| `good first issue` | Simple enough for a newcomer to tackle |
| `help wanted` | Extra attention or community help is needed |
| `invalid` | Issue is not valid (wrong repo, not reproducible, etc.) |
| `wontfix` | Acknowledged but will not be addressed |

### Custom project labels

If the project uses additional labels beyond GitHub defaults, always check available labels first:

```bash
gh label list
```

Use project-specific labels when they exist and are relevant. Do NOT create new labels without user confirmation.

## Operations

Based on `$ARGUMENTS`, perform ONE of these operations:

### `create <title>`

1. Determine the issue type from the title and context:
   - Bug indicators: "fix", "broken", "error", "crash", "fail", "wrong", "incorrect", "regression"
   - Enhancement indicators: "add", "implement", "new", "improve", "show", "allow", "support", "enable"
   - Documentation indicators: "document", "readme", "guide", "docs"
2. **Check which labels are available** in the target repository:

```bash
gh label list -R "$REPO" --json name --jq '.[].name'
```

   Compare the output against the GitHub default type labels (`bug`, `enhancement`, `documentation`, `question`). Note any that are missing.

   - If all required type labels are present: proceed normally.
   - If the expected type label is **missing**: inform the user, then either:
     - Ask the user to pick an existing label from the list as a substitute, or
     - Ask the user to confirm creating the missing label before continuing.

3. Select the matching body template (enhancement or bug) and pre-fill the "Summary" section from context. If the user has provided enough detail, fill all applicable sections. Otherwise, ask for the missing required sections — especially "Proposed Solution" with specific file paths and implementation approach.
4. Suggest appropriate labels based on the type detection and available labels discovered in step 2.
5. **Present the full issue (title, body, labels) for user review before creating.** Wait for confirmation or edits.
6. Create the issue:

```bash
gh issue create -R "$REPO" --title "<title>" --label "<label1>,<label2>" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

7. Output the issue URL.

### `view <number>`

1. Display the issue details:

```bash
gh issue view <number> -R "$REPO"
```

2. If the user wants to see discussion, show comments:

```bash
gh issue view <number> -R "$REPO" --comments
```

### `close <number> [reason]`

1. Fetch the issue to verify state:

```bash
gh issue view <number> -R "$REPO" --json title,labels,state
```

2. If the issue is already closed, inform the user and stop.
3. **If closing as duplicate**, require the user to specify the original issue number. Link and close:

```bash
gh issue comment <number> -R "$REPO" --body "Closing as duplicate of #<original>."
gh issue close <number> -R "$REPO" --reason "duplicate"
gh issue edit <number> -R "$REPO" --add-label "duplicate"
```

4. **For other closures**, add a comment explaining why, then close:

```bash
gh issue comment <number> -R "$REPO" --body "<reason>"
gh issue close <number> -R "$REPO"
```

5. If the user provides a reason in the arguments, use it. Otherwise, ask for a reason before closing — never close silently.

### `comment <number> <text>`

1. Verify the issue exists:

```bash
gh issue view <number> -R "$REPO" --json number,title,state
```

2. Add the comment:

```bash
gh issue comment <number> -R "$REPO" --body "<text>"
```

3. Confirm the comment was posted with a link.

### `label <number> <label> [--remove]`

1. Fetch available labels to validate the requested label exists:

```bash
gh label list -R "$REPO" --json name --jq '.[].name'
```

2. If `--remove` is **not** provided, add the label:

```bash
gh issue edit <number> -R "$REPO" --add-label "<label>"
```

   If `--remove` **is** provided, remove the label:

```bash
gh issue edit <number> -R "$REPO" --remove-label "<label>"
```

3. If the label does not exist, warn the user and list available labels. Suggest the closest match if possible.

### `triage`

1. List all open issues with their labels:

```bash
gh issue list -R "$REPO" --state open --json number,title,body,labels,createdAt --limit 100
```

2. Filter for issues where `labels` is empty.
3. If no unlabeled issues are found, inform the user ("All open issues are labeled") and stop.
4. Analyze the title and body of each unlabeled issue to suggest a label:
   - Bug indicators: "crash", "broken", "error", "fix", "fail", "wrong", "incorrect", "regression"
   - Enhancement indicators: "add", "implement", "improve", "new", "allow", "show", "support", "enable"
   - Documentation indicators: "readme", "docs", "guide", "document"
   - If unclear, suggest `question`
5. Present a summary table with suggested labels:

```
#   Title                                    Suggested Label
37  Add database corruption recovery         enhancement
33  Fix error state on successful ops        bug
30  Update API documentation                 documentation
```

6. Ask the user to confirm, modify, or skip each suggestion before applying.
7. Apply confirmed labels:

```bash
gh issue edit <number> -R "$REPO" --add-label "<label>"
```

### `list` (default when no arguments given)

1. List open issues:

```bash
gh issue list -R "$REPO" --state open --json number,title,labels,assignees --limit 50
```

If `--label <label>` is specified in the arguments, add `--label "<label>"` to filter.

2. Display in a readable table format:

```
#   Title                                    Labels              Assignee
12  Add dark mode toggle                     enhancement         @user
11  App crashes on startup with empty DB     bug, good first     —
10  Update README with build instructions    documentation       @user
```

3. Show summary: total count and label distribution.
4. If there are more issues than the displayed limit, inform the user and suggest using `--label` to filter or increasing the limit.

## Error handling

| Scenario | Detection | Action |
|----------|-----------|--------|
| `gh` not installed | `command -v gh` fails | Direct user to https://cli.github.com |
| Not authenticated | `gh auth status` exits non-zero | Instruct user to run `gh auth login` |
| Not in a git repo | `git rev-parse --show-toplevel` fails | Ask user for `owner/repo` manually |
| No remote configured | `git remote get-url origin` fails | Ask user for `owner/repo` manually |
| Issue not found | `gh issue view` exits non-zero | Verify the issue number and repository |
| Label not found | Label not in `gh label list` output | Show available labels, suggest closest match |
| Permission denied | `gh` returns 403/404 | Check repo access and authentication scopes |
| Rate limited | `gh` returns 429 | Wait and retry, or inform the user |

## Constraints

- Never create issues without at least one type label
- Always present the full issue for user review before creating
- Never close issues without adding a comment explaining why
- Always link duplicate issues before closing with `duplicate` label
- When editing existing issues, use `--add-label` (not `--label`) to preserve existing labels
- Do not create new labels without explicit user confirmation
- Include specific file paths and code references in issue bodies when the context is known
