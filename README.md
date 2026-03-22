# agent-tools

AI tooling repository for reusable skills, custom agents, instruction files, and prompt-driven workflows.

## Overview

This project is intended as a versioned home for practical AI development assets that can be reused, refined, and shared across tasks and repositories.

It is designed for:

- reusable task-oriented skills
- specialized custom agents
- repository-level instruction files
- prompt and workflow patterns that should evolve over time

## Available Skills

- `github-commit-pr`: end-to-end workflow for committing changes, pushing a branch, and opening or updating a GitHub pull request
- `github-do-issue`: workflow for fetching a GitHub issue, implementing it in the current repository, and stopping before commit or PR creation
- `github-issues`: standardized issue creation, labeling, triage, commenting, and issue management through the GitHub CLI

## Available Agents

There are currently no custom agents in the `agents/` directory.

## What This Repository Is For

- storing reusable AI workflow assets in one place
- versioning prompt and instruction patterns
- standardizing AI-assisted development practices
- bootstrapping new AI tooling repositories faster

## Getting Started

1. Use one of the existing GitHub-focused skills as the starting point for your workflow.
2. Add a new custom agent when the repository actually introduces one.
3. Extend repository-wide guidance through instruction files when needed.
4. Keep the README aligned with the real contents of the repository.

## Validation

The repository includes a lightweight validation workflow for documentation-heavy assets.

Run it locally with:

```bash
bash .github/scripts/validate.sh
```

The validator checks:

- required frontmatter fields
- skill and agent naming conventions
- skill directory completeness
- broken relative Markdown links

## Next Directions

- add more task-specific skills beyond GitHub workflows
- introduce custom agents once there is a clear reusable role for them
- add sample inputs and outputs for each skill

## Status

This repository currently contains a focused set of GitHub-oriented skills and the supporting validation workflow around them. The next step is to expand it only where a reusable workflow clearly exists.