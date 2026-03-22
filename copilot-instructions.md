# Copilot Instructions

This repository contains reusable AI tooling assets.

## Expectations

- Prefer minimal, well-scoped changes.
- Keep folder names and files predictable.
- Treat `README.md` as human-facing documentation.
- Treat `AGENTS.md` and `SKILL.md` files as automation-facing documentation.
- Preserve existing structure unless a change clearly improves maintainability.

## Conventions

- Store each skill in its own directory under `skills/`.
- Use `SKILL.md` as the entry file for a skill.
- Store custom agents under `agents/` using descriptive names.
- Store shared repository instructions under `.github/instructions/`.
- Use kebab-case names for new assets.

## Quality Bar

- Instructions should be specific enough to execute.
- Avoid duplicated guidance across files.
- When introducing a new asset type, document it in `README.md`.