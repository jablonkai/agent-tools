# agent-tools

Reusable AI tooling repository: skills, custom agents, instruction files, and prompt workflows. See [README.md](README.md) for full overview.

## Layout

| Path | Purpose |
|------|---------|
| `skills/<name>/SKILL.md` | Reusable skill, one directory per skill |
| `instructions/CLAUDE.md` | Global Claude instruction file; source of truth for `~/.claude/CLAUDE.md`, synced by `update-all` (`claude-md` step) |
| `scripts/update-all.sh` | Helper script to install tooling globally |
| `.github/scripts/validate.sh` | Local validation (run before committing) |

## Available Skills

- `code-analyzer`: read-only whole-project audit for bugs, security, quality, performance, tests, docs, and prioritized improvement ideas
- `duv`: DUV Ultramarathon Statistics lookup workflow
- `emu-branding`: EMU visual identity and brand guidance
- `github-commit-pr`: commit, push, and pull request workflow
- `github-do-issue`: implement a GitHub issue locally before commit or PR creation
- `github-fix-action-error`: diagnose and fix the latest failing GitHub Actions run
- `github-issues`: create, triage, label, comment on, and manage GitHub issues

## Conventions

### Skills (`skills/`)
- Directory name: **kebab-case** (e.g. `github-commit-pr`)
- Every skill dir must contain exactly one `SKILL.md`
- Required YAML frontmatter fields: `name`, `description`
- Common optional fields: `category`, `risk`, `tags`, `allowed-tools`, `argument-hint`
- Use existing skills (e.g. [github-commit-pr](skills/github-commit-pr/SKILL.md)) as a template

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
