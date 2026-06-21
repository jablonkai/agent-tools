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

- `code-analyzer`: holistic read-only project audit for bugs, security vulnerabilities, code quality issues, performance risks, missing tests, documentation gaps, and prioritized improvement ideas
- `duv`: search and retrieve data from the DUV Ultramarathon Statistics website (statistik.d-u-v.org), including runner profiles, events, and rankings
- `emu-branding`: brand guidelines and visual identity for EMU (Egyesület a Magyar Ultrafutásért), including logo, color palette, and typography
- `github-commit-pr`: end-to-end workflow for committing changes, pushing a branch, and opening or updating a GitHub pull request
- `github-do-issue`: workflow for fetching a GitHub issue, implementing it in the current repository, and stopping before commit or PR creation
- `github-fix-action-error`: diagnoses the latest failing GitHub Actions run on the current branch, applies a targeted fix locally, and — after user approval — commits and pushes (refuses to run on `main`/`master`/`develop`)
- `github-issues`: standardized issue creation, labeling, triage, commenting, and issue management through the GitHub CLI
- `markitdown`: convert PDF, Office, HTML, data, e-book, image, audio, and ZIP files (or YouTube URLs) to clean Markdown using Microsoft's markitdown tool, via CLI or Python API


## Available Agents

Custom subagents live in `agents/` as `*.agent.md` files (Claude Code subagent format: `name`, `description`, `tools`, `model`).

- `kmp-compose-dev`: Kotlin Multiplatform + Compose Multiplatform implementation and review; orchestrates the `compose-*` and `kotlin-*` skills
- `flutter-dev`: Flutter/Dart feature work, layout fixes, routing, data, and tests; orchestrates the `flutter-*` and `dart-*` skills
- `ios-macos-dev`: native iOS/macOS development (Swift, SwiftUI, UIKit/AppKit) — Xcode projects, SPM, concurrency, signing, and tests; uses the `xcode-project-setup` skill and `find-docs`
- `ultra-data`: ultramarathon data domain — DUV lookups, race results and runner profiles, multi-day race data, and Garmin/Coach training data via the `duv` skill
- `skill-smith`: maintainer agent for this repo — scaffolds and audits skills/agents to convention, syncs README/AGENTS, and runs the validator
- `delegate-scout`: read-only research agent that fans heavy reading out to the delegate CLIs (`agy`, `kiro-cli`, `cursor-agent`, `copilot`) to keep the main context clean

## What This Repository Is For

- storing reusable AI workflow assets in one place
- versioning prompt and instruction patterns
- standardizing AI-assisted development practices
- bootstrapping new AI tooling repositories faster

## Setup

The `update-all` workflow installs skills from several upstream sources, including:

- `anthropics/skills`
- `chrisbanes/skills`
- `dart-lang/skills`
- `firebase/agent-skills`
- `flutter/skills`
- `github/awesome-copilot`
- `heygen-com/hyperframes`
- `jablonkai/agent-tools`
- `kepano/obsidian-skills`
- `PicsArt/gen-ai-skills`
- `upstash/context7`

The `claude-md` step syncs [instructions/CLAUDE.md](instructions/CLAUDE.md) to `~/.claude/CLAUDE.md`, so the global Claude instruction file is versioned in this repository. Edit it here and run `update-all claude-md` (or a full `update-all`) to roll it out.

The `agents` step syncs the custom subagents in [agents/](agents/) to `~/.claude/agents/` (each `agents/<name>.agent.md` is installed as `<name>.md`, Claude Code's expected extension), so they are available globally from any project. Edit them here and run `update-all agents` (or a full `update-all`) to roll them out.

To make the `update-all` script available from anywhere in your terminal:

```bash
cp scripts/update-all.sh /usr/local/bin/update-all
chmod +x /usr/local/bin/update-all
```

Then you can run it from any directory:

```bash
update-all
```

### Bootstrapping a new machine

On a fresh machine, run the `init` bootstrap subcommand to install the whole toolchain from scratch, then fall through to a normal update:

```bash
update-all init
```

It idempotently installs the Xcode Command Line Tools, Homebrew, node, git, pipx, uv, the Android CLI (plus `android init` and the core Android SDK — platform-tools, emulator, a platform, and build-tools), `gh`, `mo`, the agent CLIs (`claude`, `copilot`, `codex`, `agy`, `cursor`, `opencode`, `kilo`, `kiro`), `gen-ai`, `ctx7`, `playwright-cli`, `markitdown`, Flutter (manual install), and SDKMAN. The trailing `sdk` step then installs and warms up the Kotlin toolchain via SDKMAN's `kotlintoolchain` candidate. Tools already present are skipped, so re-running `init` on a provisioned machine is safe. At the end it prints a reminder listing the tools that still need an interactive login (the installers don't sign you in).

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

This repository currently contains a focused set of reusable workflow skills and the supporting validation workflow around them. The next step is to expand it only where a reusable workflow clearly exists.
