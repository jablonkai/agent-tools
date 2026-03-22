# AGENTS.md

## Project Overview

This repository stores reusable AI development assets, including custom skills, custom agents, repository instructions, and related prompt artifacts.

The goal is to keep these assets versioned, documented, and easy to evolve over time.

## Repository Structure

- `skills/`: reusable skills, each in its own directory with a `SKILL.md`
- `agents/`: agent definition files for specialized workflows
- `.github/instructions/`: repository-scoped instruction files
- `copilot-instructions.md`: shared guidance for contributors and coding agents
- `README.md`: human-facing project overview

## Setup Commands

- Initialize git if needed: `git init -b main`
- Check repository status: `git status`
- List files quickly: `rg --files`

This repository currently has no runtime dependencies.

## Development Workflow

- Add new skills under `skills/<skill-name>/SKILL.md`
- Add new agents under `agents/*.agent.md`
- Add cross-cutting repo guidance to `.github/instructions/*.instructions.md`
- Keep `README.md` human-focused and `AGENTS.md` agent-focused

## Writing Guidelines

- Keep skill instructions concrete and actionable
- Prefer reusable templates over one-off prompts
- Document intended use cases and constraints in each asset
- Avoid vague wording when a file is meant for automation

## Testing Instructions

There is no automated test suite yet.

For content changes:

- validate Markdown structure manually
- check that referenced paths exist
- verify naming consistency for `SKILL.md`, `.agent.md`, and `.instructions.md`

## Code Style And File Naming

- Use Markdown for instructions and prompt assets
- Use kebab-case for directories and file names where possible
- Keep each skill self-contained in its own folder
- Use short sections and scannable bullet lists

## Pull Request Guidance

- Keep changes focused on one logical capability at a time
- Update `README.md` when the repository purpose or layout changes
- Update this file when agent workflow expectations change

## Common Patterns

- One skill per directory
- One agent per file
- One instruction concern per file

## Future Extensions

- add validation scripts for structure checks
- add prompt templates for common tasks
- add examples or fixtures for each skill