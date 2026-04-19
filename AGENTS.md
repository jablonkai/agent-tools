# agent-tools

Reusable AI tooling repository: skills, custom agents, instruction files, and prompt workflows. See [README.md](README.md) for full overview.

## Layout

| Path | Purpose |
|------|---------|
| `skills/<name>/SKILL.md` | Reusable skill, one directory per skill |
| `agents/<name>.agent.md` | Custom agent definitions |
| `.github/instructions/*.instructions.md` | Repository-scoped instruction files |
| `scripts/update-all.sh` | Helper script to install tooling globally |
| `.github/scripts/validate.sh` | Local validation (run before committing) |

## Conventions

### Skills (`skills/`)
- Directory name: **kebab-case** (e.g. `github-commit-pr`)
- Every skill dir must contain exactly one `SKILL.md`
- Required YAML frontmatter fields: `name`, `description`
- Common optional fields: `category`, `risk`, `tags`, `allowed-tools`, `argument-hint`
- Use existing skills (e.g. [github-commit-pr](skills/github-commit-pr/SKILL.md)) as a template

### Agents (`agents/`)
- File naming: `<name>.agent.md` — files not ending in `.agent.md` will fail validation
- Required YAML frontmatter fields: `name`, `description`

### Instruction files (`.github/instructions/`)
- File naming: `*.instructions.md`
- Required YAML frontmatter field: `applyTo`

## Validation

Always run before committing:

```bash
bash .github/scripts/validate.sh
```

Checks: frontmatter completeness, agent file naming, skill directory structure, kebab-case names, broken relative Markdown links.

## Adding a new skill

1. Create `skills/<kebab-name>/SKILL.md` with valid frontmatter
2. Run `bash .github/scripts/validate.sh`
3. Add an entry to the **Available Skills** table in [README.md](README.md)
