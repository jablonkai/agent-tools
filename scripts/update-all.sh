#!/usr/bin/env bash
# Updates all dev tooling on this machine.
# Each step is visually separated; failures in one step do not abort the rest.
# Run `update-all.sh --help` for options.

set -u

# ---------- skill configuration ----------
# Target agents / directories every skill gets installed into.
# Each entry is one of:
#   agent:<name>   — use `gh skill install --agent <name> --scope user`
#                    supported: github-copilot | claude-code | cursor | codex | gemini | antigravity
#   dir:<path>     — use `gh skill install --dir <path>` (custom directory)
SKILL_TARGETS=(
  "agent:claude-code"
  "agent:antigravity"
  "dir:$HOME/.agents/skills"
)

# Skills to install/update via `gh skill`.
# Format per entry: "REPO|SKILL_PATH"
#   REPO       — OWNER/REPO on GitHub
#   SKILL_PATH — directory path of the skill inside the repo (the folder
#                containing SKILL.md). `gh skill install` resolves it via
#                its built-in discovery.
# Note: android/skills are managed separately by the `android` CLI step.
# Android skills — installed via the `android` CLI (see do_android_skills).
# These go into the same targets as SKILLS. agent: targets are handled
# natively by `android skills add --agent`; dir: targets are synced
# afterwards by copying from one of the installed agent dirs.
ANDROID_SKILLS=(
  "navigation-3"
  "r8-analyzer"
  "edge-to-edge"
)

# Maps each supported `agent:` name to its on-disk skills directory.
# Used when rsyncing android skills into dir: targets.
agent_skills_dir() {
  case "$1" in
    claude-code)    echo "$HOME/.claude/skills" ;;
    antigravity)    echo "$HOME/.gemini/antigravity/skills" ;;
    github-copilot) echo "$HOME/.github-copilot/skills" ;;
    cursor)         echo "$HOME/.cursor/skills" ;;
    codex)          echo "$HOME/.codex/skills" ;;
    gemini)         echo "$HOME/.gemini/skills" ;;
    *)              return 1 ;;
  esac
}

# Given a SKILL_TARGETS entry (e.g. "agent:claude-code" or "dir:/path"),
# print its on-disk skills directory. Returns nonzero for unknown targets.
resolve_target_dir() {
  local kind="${1%%:*}" value="${1#*:}"
  case "$kind" in
    agent) agent_skills_dir "$value" ;;
    dir)   echo "$value" ;;
    *)     return 1 ;;
  esac
}

SKILLS=(
  # anthropics/skills
  "anthropics/skills|skills/canvas-design"
  "anthropics/skills|skills/frontend-design"
  "anthropics/skills|skills/skill-creator"
  "anthropics/skills|skills/theme-factory"

  # firebase/agent-skills
  "firebase/agent-skills|skills/firebase-app-hosting-basics"
  "firebase/agent-skills|skills/firebase-auth-basics"
  "firebase/agent-skills|skills/firebase-basics"
  "firebase/agent-skills|skills/firebase-firestore-standard"
  "firebase/agent-skills|skills/firebase-hosting-basics"
  "firebase/agent-skills|skills/firebase-security-rules-auditor"

  # github/awesome-copilot
  "github/awesome-copilot|skills/gh-cli"
  "github/awesome-copilot|skills/draw-io-diagram-generator"
  "github/awesome-copilot|skills/gdpr-compliant"

  # jablonkai/agent-tools
  "jablonkai/agent-tools|skills/emu-branding"
  "jablonkai/agent-tools|skills/github-commit-pr"
  "jablonkai/agent-tools|skills/github-do-issue"
  "jablonkai/agent-tools|skills/github-fix-action-error"
  "jablonkai/agent-tools|skills/github-issues"

  # upstash/context7
  "upstash/context7|skills/find-docs"
)

# Force Homebrew to emit its progress output even when stdout isn't
# attached to an interactive terminal (e.g. when the script is piped).
export HOMEBREW_COLOR=1
export HOMEBREW_NO_ENV_HINTS=1

# ---------- pretty printing ----------
BOLD=$'\033[1m'
GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# Brand colors (256-color ANSI, approximating official palettes)
C_HOMEBREW=$'\033[38;5;215m'   # amber/orange
C_ANDROID=$'\033[38;5;41m'     # green (#3DDC84)
C_FLUTTER=$'\033[38;5;39m'     # blue (#13B9FD)
C_RUST=$'\033[38;5;166m'       # rust orange (#CE422B)
C_PYTHON=$'\033[38;5;220m'     # python yellow
C_GITHUB=$'\033[38;5;141m'     # purple/violet
C_SKILLS=$'\033[38;5;51m'      # cyan (agent-tools)
C_MO=$'\033[38;5;201m'         # magenta
C_APPLE=$'\033[38;5;250m'      # silver/gray

# ---------- step registry ----------
# Ordered list of steps. Format: "ID|COLOR_VAR|TITLE"
# The ID is what the user passes to --only/--skip (and as positional args).
# Each ID maps to a function named do_<id> (hyphens → underscores).
STEPS=(
  "brew|C_HOMEBREW|Homebrew: update + upgrade + cleanup"
  "android|C_ANDROID|Android CLI: update"
  "android-skills|C_ANDROID|Android skills: install/update via android skills add"
  "flutter|C_FLUTTER|Flutter: upgrade"
  "rust|C_RUST|Rust toolchain: rustup update"
  "pipx|C_PYTHON|pipx: upgrade all packages"
  "gh-ext|C_GITHUB|GitHub CLI extensions: upgrade all"
  "skills|C_SKILLS|Agent skills: install/update via gh skill"
  "cleanup|C_APPLE|Cleanup: npm/pnpm cache + Library/Caches"
  "mo-clean|C_MO|mo: clean"
  "mo-optimize|C_MO|mo: optimize"
  "macos|C_APPLE|macOS system updates (check only)"
)

STEP_NUM=0
CURRENT_COLOR="$DIM"
declare -a RESULTS=()

hr() {
  local color="${1:-$DIM}"
  printf '%s────────────────────────────────────────────────────────────────────────%s\n' "$color" "${RESET}"
}

step() {
  local color="$1"; shift
  local title="$1"
  CURRENT_COLOR="$color"
  STEP_NUM=$((STEP_NUM + 1))
  echo
  hr "$color"
  printf '%s%s▶ [%d] %s%s\n' "${BOLD}" "$color" "$STEP_NUM" "$title" "${RESET}"
  hr "$color"
}

run() {
  local label="$1"; shift
  local start end dur status
  start=$(date +%s)
  "$@"
  local rc=$?
  if [[ "$rc" == "0" ]]; then status="ok"; else status="fail"; fi
  end=$(date +%s)
  dur=$((end - start))
  if [[ "$status" == "ok" ]]; then
    printf '%s✓ %s%s %s(%ds)%s\n' "${GREEN}" "$label" "${RESET}" "${DIM}" "$dur" "${RESET}"
    RESULTS+=("${GREEN}✓${RESET} ${CURRENT_COLOR}${label}${RESET} ${DIM}(${dur}s)${RESET}")
  else
    printf '%s✗ %s%s %s(%ds)%s\n' "${RED}" "$label" "${RESET}" "${DIM}" "$dur" "${RESET}"
    RESULTS+=("${RED}✗${RESET} ${CURRENT_COLOR}${label}${RESET} ${DIM}(${dur}s)${RESET}")
  fi
}

skip() {
  local label="$1"
  local reason="$2"
  local no_summary="${3:-}"
  printf '%s⊘ %s — %s%s\n' "${YELLOW}" "$label" "$reason" "${RESET}"
  [[ -z "$no_summary" ]] && RESULTS+=("${YELLOW}⊘${RESET} ${CURRENT_COLOR}${label}${RESET} ${DIM}(skipped: ${reason})${RESET}")
}

have() { command -v "$1" >/dev/null 2>&1; }

# Like run(), but only records to RESULTS if the watched directory changed.
# Usage: run_if_changed "label" "/path/to/watch" cmd [args...]
run_if_changed() {
  local label="$1" watch_dir="$2"; shift 2
  local before after start end dur
  before=$(find "$watch_dir" -type f 2>/dev/null | sort | xargs shasum 2>/dev/null | shasum | cut -d' ' -f1)
  start=$(date +%s)
  "$@"
  local rc=$?
  end=$(date +%s)
  dur=$((end - start))
  after=$(find "$watch_dir" -type f 2>/dev/null | sort | xargs shasum 2>/dev/null | shasum | cut -d' ' -f1)
  if [[ "$rc" == "0" ]]; then
    printf '%s✓ %s%s %s(%ds)%s\n' "${GREEN}" "$label" "${RESET}" "${DIM}" "$dur" "${RESET}"
    [[ "$before" != "$after" ]] && RESULTS+=("${GREEN}✓${RESET} ${CURRENT_COLOR}${label}${RESET} ${DIM}(${dur}s)${RESET}")
  else
    printf '%s✗ %s%s %s(%ds)%s\n' "${RED}" "$label" "${RESET}" "${DIM}" "$dur" "${RESET}"
    RESULTS+=("${RED}✗${RESET} ${CURRENT_COLOR}${label}${RESET} ${DIM}(${dur}s)${RESET}")
  fi
}

# ---------- step implementations ----------

do_brew() {
  if have brew; then
    # --verbose so fetched taps / up-to-date lines are always visible.
    run "brew update"  brew update --verbose
    run "brew upgrade" brew upgrade --verbose
    run "brew cleanup" brew cleanup
  else
    skip "brew" "not installed"
  fi
}

do_android() {
  if have android; then
    run "android update" android update
  else
    skip "android" "not installed"
  fi
}

do_android_skills() {
  if ! have android; then
    skip "android skills" "android not installed"
    return
  fi

  # Partition SKILL_TARGETS into agent: and dir: lists.
  local target kind value agents="" first_agent=""
  local dirs=()
  for target in "${SKILL_TARGETS[@]}"; do
    kind="${target%%:*}"
    value="${target#*:}"
    case "$kind" in
      agent)
        agents+="${agents:+,}$value"
        [[ -z "$first_agent" ]] && first_agent="$value"
        ;;
      dir) dirs+=("$value") ;;
    esac
  done

  if [[ -z "$agents" ]]; then
    skip "android skills add" "no agent: targets in SKILL_TARGETS"
    return
  fi

  local skill
  for skill in "${ANDROID_SKILLS[@]}"; do
    run "android skills add --skill $skill → $agents" \
      android skills add --skill "$skill" --agent "$agents"
  done

  # Sync into dir: targets by copying from the first agent's install dir.
  if ((${#dirs[@]})); then
    local src_dir
    if ! src_dir=$(agent_skills_dir "$first_agent"); then
      skip "android skills → dir targets" "unknown agent dir for $first_agent"
      return
    fi
    local d skill src
    for d in "${dirs[@]}"; do
      mkdir -p "$d"
      for skill in "${ANDROID_SKILLS[@]}"; do
        src="$src_dir/$skill"
        if [[ -d "$src" ]]; then
          run "rsync $skill → $d" rsync -a --delete "$src/" "$d/$skill/"
        else
          skip "rsync $skill → $d" "source not found: $src"
        fi
      done
    done
  fi
}

do_flutter() {
  if have flutter; then
    run "flutter upgrade" flutter upgrade
  else
    skip "flutter" "not installed"
  fi
}

do_rust() {
  if have rustup; then
    run "rustup update" rustup update
  else
    skip "rustup" "not installed"
  fi
}

do_pipx() {
  if have pipx; then
    run "pipx upgrade-all" pipx upgrade-all
  else
    skip "pipx" "not installed"
  fi
}

do_gh_ext() {
  if have gh; then
    run "gh extension upgrade --all" gh extension upgrade --all
  else
    skip "gh" "not installed"
  fi
}

do_skills() {
  if ! have gh; then
    skip "gh skill" "gh CLI not installed"
    return
  fi

  local entry repo path target skill_name target_dir
  local first_agent="" agent_targets=() dirs=()

  for target in "${SKILL_TARGETS[@]}"; do
    local kind="${target%%:*}" value="${target#*:}"
    case "$kind" in
      agent) agent_targets+=("$target"); [[ -z "$first_agent" ]] && first_agent="$value" ;;
      dir)   dirs+=("$value") ;;
    esac
  done

  local src_base=""
  [[ -n "$first_agent" ]] && src_base=$(agent_skills_dir "$first_agent")

  # For each skill: install or update in agent: targets, then immediately
  # mirror to dir: targets so they always reflect the latest version.
  for entry in "${SKILLS[@]}"; do
    IFS='|' read -r repo path <<< "$entry"
    skill_name="${path##*/}"

    for target in "${agent_targets[@]}"; do
      if ! target_dir=$(resolve_target_dir "$target"); then
        echo "unknown SKILL_TARGETS entry: $target" >&2
        continue
      fi
      mkdir -p "$target_dir"
      if [[ ! -f "$target_dir/$skill_name/SKILL.md" ]]; then
        run "gh skill install $skill_name → $target" \
          gh skill install "$repo" "$path" --dir "$target_dir"
      else
        run_if_changed "gh skill update $skill_name → $target" "$target_dir/$skill_name" \
          gh skill update "$skill_name" --dir "$target_dir" --all
      fi
    done

    # Mirror to every dir: target right after the agent: install/update.
    if [[ -n "$src_base" && ${#dirs[@]} -gt 0 ]]; then
      local src="$src_base/$skill_name" d
      if [[ -d "$src" ]]; then
        for d in "${dirs[@]}"; do
          mkdir -p "$d"
          run_if_changed "rsync $skill_name → $d" "$d/$skill_name" \
            rsync -a --delete "$src/" "$d/$skill_name/"
        done
      else
        for d in "${dirs[@]}"; do
          skip "rsync $skill_name → $d" "not yet installed in $first_agent" "no_summary"
        done
      fi
    fi
  done
}

do_cleanup() {
  # npm cache cleanup
  if have npm; then
    run "npm cache clean" npm cache clean --force
  else
    skip "npm cache clean" "npm not installed"
  fi

  # pnpm cache cleanup
  if have pnpm; then
    run "pnpm store prune" pnpm store prune
  else
    skip "pnpm store prune" "pnpm not installed"
  fi

  # Yarn cache cleanup
  if have yarn; then
    run "yarn cache clean" yarn cache clean
  else
    skip "yarn cache clean" "yarn not installed"
  fi

  # Deno cache cleanup
  if [[ -d "$HOME/.deno" ]]; then
    run "rm -rf ~/.deno" rm -rf "$HOME"/.deno
  else
    skip "deno cache cleanup" "deno not found"
  fi

  # Bun cache cleanup
  if [[ -d "$HOME/.bun/install/cache" ]]; then
    run "rm -rf ~/.bun/install/cache" rm -rf "$HOME"/.bun/install/cache
  else
    skip "bun cache cleanup" "bun cache not found"
  fi

  # Playwright cache cleanup
  if [[ -d "$HOME/.cache/ms-playwright" ]]; then
    run "rm -rf ~/.cache/ms-playwright" rm -rf "$HOME"/.cache/ms-playwright
  else
    skip "playwright cache cleanup" "playwright cache not found"
  fi

  # pip cache cleanup
  if have pip; then
    run "pip cache purge" pip cache purge
  else
    skip "pip cache purge" "pip not installed"
  fi

  # Poetry cache cleanup
  if have poetry; then
    run "poetry cache clear" poetry cache clear --all
  else
    skip "poetry cache clear" "poetry not installed"
  fi

  # Gem cache cleanup
  if have gem; then
    run "gem cleanup" gem cleanup
  else
    skip "gem cleanup" "gem not installed"
  fi

  # Maven cache cleanup
  if [[ -d "$HOME/.m2/repository" ]]; then
    run "rm -rf ~/.m2/repository" rm -rf "$HOME"/.m2/repository
  else
    skip "maven cache cleanup" "maven cache not found"
  fi

  # Gradle cache cleanup
  if [[ -d "$HOME/.gradle/caches" ]]; then
    # Stop gradle daemon if running (prevents lock issues)
    if have gradle; then
      gradle --stop 2>/dev/null || true
    fi
    run "rm -rf ~/.gradle/caches" rm -rf "$HOME"/.gradle/caches
  else
    skip "gradle cache cleanup" "gradle cache not found"
  fi

  # Cargo cache cleanup
  if [[ -d "$HOME/.cargo/registry/cache" ]]; then
    run "rm -rf ~/.cargo/registry/cache" rm -rf "$HOME"/.cargo/registry/cache
  else
    skip "cargo cache cleanup" "cargo cache not found"
  fi

  # Go cache cleanup
  if [[ -d "$HOME/.cache/go-build" ]]; then
    run "rm -rf ~/.cache/go-build" rm -rf "$HOME"/.cache/go-build
  else
    skip "go cache cleanup" "go cache not found"
  fi

  # CocoaPods cache cleanup
  if [[ -d "$HOME/.cocoapods/repos" ]]; then
    run "rm -rf ~/.cocoapods/repos" rm -rf "$HOME"/.cocoapods/repos
  else
    skip "cocoapods cache cleanup" "cocoapods not found"
  fi

  # Xcode Derived Data cleanup
  if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
    run "rm -rf ~/Library/Developer/Xcode/DerivedData" rm -rf "$HOME"/Library/Developer/Xcode/DerivedData
  else
    skip "xcode derived data cleanup" "xcode not found"
  fi

  # .NET cache cleanup
  if have dotnet; then
    run "dotnet nuget locals all --clear" dotnet nuget locals all --clear
  else
    skip "dotnet cache cleanup" "dotnet not installed"
  fi

  # SwiftPM cache cleanup
  if [[ -d "$HOME/.swiftpm" ]]; then
    run "rm -rf ~/.swiftpm" rm -rf "$HOME"/.swiftpm
  else
    skip "swiftpm cache cleanup" "swiftpm not found"
  fi

  # JetBrains IDE caches cleanup
  if [[ -d "$HOME/.cache/JetBrains" ]]; then
    run "rm -rf ~/.cache/JetBrains" rm -rf "$HOME"/.cache/JetBrains
  else
    skip "jetbrains cache cleanup" "jetbrains cache not found"
  fi

  # Android Studio cache cleanup
  if [[ -d "$HOME/Library/Caches/Google" ]]; then
    run "rm -rf ~/Library/Caches/Google/AndroidStudio*" rm -rf "$HOME"/Library/Caches/Google/AndroidStudio*
  else
    skip "android studio cache cleanup" "android studio not found"
  fi

  # Bazel cache cleanup
  if [[ -d "$HOME/.bazel" ]]; then
    run "rm -rf ~/.bazel" rm -rf "$HOME"/.bazel
  else
    skip "bazel cache cleanup" "bazel not found"
  fi

  # Pants cache cleanup
  if [[ -d "$HOME/.cache/pants" ]]; then
    run "rm -rf ~/.cache/pants" rm -rf "$HOME"/.cache/pants
  else
    skip "pants cache cleanup" "pants not found"
  fi

  # Docker cache cleanup
  if have docker; then
    run "docker system prune -f" docker system prune -f
  else
    skip "docker system prune" "docker not installed"
  fi

  # Brew cleanup
  if have brew; then
    run "brew cleanup --prune" brew cleanup --prune=all
  else
    skip "brew cleanup" "brew not installed"
  fi

  # Library/Caches cleanup
  run "rm -rf ~/Library/Caches/*" rm -rf "$HOME"/Library/Caches/*
}
do_mo_clean() {
  if have mo; then
    run "mo clean" mo clean
  else
    skip "mo" "not installed"
  fi
}

do_mo_optimize() {
  if have mo; then
    run "mo optimize" mo optimize
  else
    skip "mo" "not installed"
  fi
}

do_macos() {
  if have softwareupdate; then
    run "softwareupdate -l" softwareupdate -l
  else
    skip "softwareupdate" "not available"
  fi
}

# ---------- argument parsing ----------

usage() {
  cat <<EOF
${BOLD}Usage:${RESET} $(basename "$0") [options] [step-id ...]

Runs dev-tool update steps in order. Without arguments every step runs.
Failures in one step do not abort the rest.

${BOLD}Options:${RESET}
  -h, --help            Show this help and exit
  -l, --list            List available step IDs and exit
  -o, --only IDS        Comma-separated list of step IDs to run
                        (may be passed multiple times; combines with positional IDs)
  -s, --skip IDS        Comma-separated list of step IDs to skip
                        (may be passed multiple times; applied after --only)

Positional arguments are treated as extra --only entries.

${BOLD}Available steps:${RESET}
$(for entry in "${STEPS[@]}"; do
    IFS='|' read -r id color title <<< "$entry"
    printf '  %-12s %s\n' "$id" "$title"
  done)

${BOLD}Examples:${RESET}
  # Run every step
  $(basename "$0")

  # Only Homebrew + Flutter
  $(basename "$0") brew flutter
  $(basename "$0") --only brew,flutter

  # Everything except the skills step and macOS check
  $(basename "$0") --skip skills,macos

  # Only the skills step
  $(basename "$0") -o skills
EOF
}

list_steps() {
  for entry in "${STEPS[@]}"; do
    IFS='|' read -r id color title <<< "$entry"
    printf '%-12s  %s\n' "$id" "$title"
  done
}

ONLY=()
SKIP_LIST=()

add_csv() {
  local arr_name="$1"
  local csv="$2"
  local IFS=','
  local item
  for item in $csv; do
    [[ -n "$item" ]] && eval "${arr_name}+=(\"\$item\")"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -l|--list) list_steps; exit 0 ;;
    -o|--only)
      [[ $# -ge 2 ]] || { echo "error: --only requires an argument" >&2; exit 2; }
      add_csv ONLY "$2"; shift 2 ;;
    --only=*) add_csv ONLY "${1#--only=}"; shift ;;
    -s|--skip)
      [[ $# -ge 2 ]] || { echo "error: --skip requires an argument" >&2; exit 2; }
      add_csv SKIP_LIST "$2"; shift 2 ;;
    --skip=*) add_csv SKIP_LIST "${1#--skip=}"; shift ;;
    --) shift; while [[ $# -gt 0 ]]; do ONLY+=("$1"); shift; done ;;
    -*) echo "error: unknown option: $1" >&2; echo; usage >&2; exit 2 ;;
    *) ONLY+=("$1"); shift ;;
  esac
done

# Validate IDs against the step registry.
valid_id() {
  local needle="$1" entry id
  for entry in "${STEPS[@]}"; do
    id="${entry%%|*}"
    [[ "$id" == "$needle" ]] && return 0
  done
  return 1
}

for id in ${ONLY[@]+"${ONLY[@]}"} ${SKIP_LIST[@]+"${SKIP_LIST[@]}"}; do
  if ! valid_id "$id"; then
    echo "error: unknown step id: $id" >&2
    echo "run '$(basename "$0") --list' to see available IDs" >&2
    exit 2
  fi
done

should_run() {
  local id="$1" x
  if ((${#ONLY[@]})); then
    local in_only=0
    for x in "${ONLY[@]}"; do [[ "$x" == "$id" ]] && { in_only=1; break; }; done
    ((in_only)) || return 1
  fi
  if ((${#SKIP_LIST[@]})); then
    for x in "${SKIP_LIST[@]}"; do [[ "$x" == "$id" ]] && return 1; done
  fi
  return 0
}

# ---------- run ----------

for entry in "${STEPS[@]}"; do
  IFS='|' read -r id color_var title <<< "$entry"
  should_run "$id" || continue
  step "${!color_var}" "$title"
  "do_${id//-/_}"
done

# ---------- summary ----------
echo
hr
printf '%sSummary%s\n' "${BOLD}" "${RESET}"
hr
if ((${#RESULTS[@]} == 0)); then
  printf '  %s(no steps ran — check --only/--skip)%s\n' "${DIM}" "${RESET}"
else
  for line in "${RESULTS[@]}"; do
    printf '  %s\n' "$line"
  done
fi
hr
