#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$repo_root"

echo "Validating repository structure and documentation..."

check_skill_frontmatter() {
  local file

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    if [[ $(head -n 1 "$file") != "---" ]]; then
      echo "Missing YAML frontmatter start: $file"
      exit 1
    fi

    if ! grep -Eq '^name:' "$file"; then
      echo "Missing name field: $file"
      exit 1
    fi

    if ! grep -Eq '^description:' "$file"; then
      echo "Missing description field: $file"
      exit 1
    fi
  done < <(find skills -type f -name 'SKILL.md' | sort)
}

check_agent_frontmatter() {
  local file

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    if [[ $(head -n 1 "$file") != "---" ]]; then
      echo "Missing YAML frontmatter start: $file"
      exit 1
    fi

    if ! grep -Eq '^name:' "$file"; then
      echo "Missing name field: $file"
      exit 1
    fi

    if ! grep -Eq '^description:' "$file"; then
      echo "Missing description field: $file"
      exit 1
    fi

  done < <(find agents -type f -name '*.agent.md' | sort)
}

check_instruction_frontmatter() {
  local file

  [[ -d .github/instructions ]] || return 0

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    if [[ $(head -n 1 "$file") != "---" ]]; then
      echo "Missing YAML frontmatter start: $file"
      exit 1
    fi

    if ! grep -Eq '^applyTo:' "$file"; then
      echo "Missing applyTo field: $file"
      exit 1
    fi
  done < <(find .github/instructions -type f -name '*.instructions.md' | sort)
}

check_agent_names() {
  local invalid

  invalid=$(find agents -type f -name '*.md' ! -name '*.agent.md' -print)
  if [[ -n "$invalid" ]]; then
    echo "Agent files must end with .agent.md"
    echo "$invalid"
    exit 1
  fi
}

check_skill_structure() {
  local dir

  while IFS= read -r dir; do
    [[ -f "$dir/SKILL.md" ]] || {
      echo "Missing SKILL.md in: $dir"
      exit 1
    }
  done < <(find skills -mindepth 1 -maxdepth 1 -type d | sort)
}

check_kebab_case_skill_dirs() {
  local dir_name

  while IFS= read -r dir_name; do
    [[ "$dir_name" =~ ^[a-z0-9]+([.-][a-z0-9]+)*(-[a-z0-9]+([.-][a-z0-9]+)*)*$ ]] || {
      echo "Skill directory must use kebab-case: skills/$dir_name"
      exit 1
    }
  done < <(find skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
}

check_markdown_links() {
  local file
  local file_dir
  local target
  local resolved_target

  while IFS= read -r file; do
    file_dir=$(dirname "$file")

    while IFS= read -r target; do
      [[ -n "$target" ]] || continue

      if [[ "$target" == http://* || "$target" == https://* || "$target" == mailto:* || "$target" == \\#* ]]; then
        continue
      fi

      target=${target%%#*}
      [[ -n "$target" ]] || continue

      if [[ "$target" == /* ]]; then
        resolved_target="$target"
      else
        resolved_target="$file_dir/$target"
      fi

      if [[ ! -e "$resolved_target" ]]; then
        echo "Broken relative Markdown link in $file: $target"
        exit 1
      fi
    done < <(grep -oE '\[[^]]+\]\(([^)]+)\)' "$file" | sed -E 's/.*\(([^)]+)\)/\1/' | sort -u)
  done < <(find . -type f -name '*.md' -not -path './.git/*' | sort)
}

check_skill_frontmatter
check_agent_frontmatter
check_instruction_frontmatter
check_agent_names
check_skill_structure
check_kebab_case_skill_dirs
check_markdown_links

echo "Validation passed."