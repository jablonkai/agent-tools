#!/usr/bin/env bash
# Updates all dev tooling on this machine.
# Each step is visually separated; failures in one step do not abort the rest.
# Run `update-all.sh --help` for options.

set -u

# ---------- skill configuration ----------
# Target agents every skill gets installed into.
# Names follow the `android skills add --agent` convention. The `gh skill`
# step remaps `common` → `universal` since gh uses that name for the same
# shared `~/.config/agents/skills` location.
SKILL_TARGETS=(
  "claude-code"
  "antigravity"
  "common"
)

# Skills to install/update via `gh skill`.
# Format per entry: "REPO|SKILL_PATH"
#   REPO       — OWNER/REPO on GitHub
#   SKILL_PATH — directory path of the skill inside the repo (the folder
#                containing SKILL.md). `gh skill install` resolves it via
#                its built-in discovery.
# Note: android/skills are managed separately by the `android` CLI step.
# Android skills — installed via the `android` CLI (see do_android_skills).
# These go into the same targets as SKILL_TARGETS, used as-is.
ANDROID_SKILLS=(
  "adaptive"
  "android-cli"
  "appfunctions"
  "edge-to-edge"
  "navigation-3"
  "perfetto-sql"
  "perfetto-trace-analysis"
  "r8-analyzer"
  "styles"
  "testing-setup"
  "verified-email"
)

# Maps each supported target name to its on-disk skills directory.
agent_skills_dir() {
  case "$1" in
    claude-code)    echo "$HOME/.claude/skills" ;;
    antigravity)    echo "$HOME/.gemini/antigravity/skills" ;;
    common)         echo "$HOME/.agents/skills" ;;
    *)              return 1 ;;
  esac
}

SKILLS=(
  # android/skills
  # "android/skills|navigation/navigation-3"
  # "android/skills|performance/r8-analyzer"
  # "android/skills|system/edge-to-edge"

  # anthropics/skills
  "anthropics/skills|skills/algorithmic-art"
  "anthropics/skills|skills/canvas-design"
  "anthropics/skills|skills/doc-coauthoring"
  "anthropics/skills|skills/docx"
  "anthropics/skills|skills/frontend-design"
  "anthropics/skills|skills/pdf"
  "anthropics/skills|skills/pptx"
  "anthropics/skills|skills/skill-creator"
  "anthropics/skills|skills/theme-factory"
  "anthropics/skills|skills/web-artifacts-builder"
  "anthropics/skills|skills/webapp-testing"
  "anthropics/skills|skills/xlsx"

  # chrisbanes/skills
  "chrisbanes/skills|skills/compose-animations"
  "chrisbanes/skills|skills/compose-focus-navigation"
  "chrisbanes/skills|skills/compose-modifier-and-layout-style"
  "chrisbanes/skills|skills/compose-recomposition-performance"
  "chrisbanes/skills|skills/compose-side-effects"
  "chrisbanes/skills|skills/compose-slot-api-pattern"
  "chrisbanes/skills|skills/compose-stability-diagnostics"
  "chrisbanes/skills|skills/compose-state-authoring"
  "chrisbanes/skills|skills/compose-state-deferred-reads"
  "chrisbanes/skills|skills/compose-state-holder-ui-split"
  "chrisbanes/skills|skills/compose-state-hoisting"
  "chrisbanes/skills|skills/compose-ui-testing-patterns"
  "chrisbanes/skills|skills/kotlin-coroutines-structured-concurrency"
  "chrisbanes/skills|skills/kotlin-flow-state-event-modeling"
  "chrisbanes/skills|skills/kotlin-multiplatform-expect-actual"
  "chrisbanes/skills|skills/kotlin-types-value-class"
  "chrisbanes/skills|skills/shepherd"

  # dart-lang/skills
  "dart-lang/skills|skills/dart-add-unit-test"
  "dart-lang/skills|skills/dart-build-cli-app"
  "dart-lang/skills|skills/dart-collect-coverage"
  "dart-lang/skills|skills/dart-fix-runtime-errors"
  "dart-lang/skills|skills/dart-generate-test-mocks"
  "dart-lang/skills|skills/dart-migrate-to-checks-package"
  "dart-lang/skills|skills/dart-resolve-package-conflicts"
  "dart-lang/skills|skills/dart-run-static-analysis"
  "dart-lang/skills|skills/dart-use-pattern-matching"

  # firebase/agent-skills
  "firebase/agent-skills|skills/firebase-ai-logic-basics"
  "firebase/agent-skills|skills/firebase-app-hosting-basics"
  "firebase/agent-skills|skills/firebase-auth-basics"
  "firebase/agent-skills|skills/firebase-basics"
  "firebase/agent-skills|skills/firebase-crashlytics"
  "firebase/agent-skills|skills/firebase-data-connect-basics"
  "firebase/agent-skills|skills/firebase-firestore"
  "firebase/agent-skills|skills/firebase-firestore-standard"
  "firebase/agent-skills|skills/firebase-hosting-basics"
  "firebase/agent-skills|skills/firebase-remote-config-basics"
  "firebase/agent-skills|skills/firebase-security-rules-auditor"
  "firebase/agent-skills|skills/xcode-project-setup"

  # flutter/skills
  "flutter/skills|skills/flutter-accessibility-audit"
  "flutter/skills|skills/flutter-add-integration-test"
  "flutter/skills|skills/flutter-add-widget-preview"
  "flutter/skills|skills/flutter-add-widget-test"
  "flutter/skills|skills/flutter-apply-architecture-best-practices"
  "flutter/skills|skills/flutter-build-responsive-layout"
  "flutter/skills|skills/flutter-fix-layout-issues"
  "flutter/skills|skills/flutter-implement-json-serialization"
  "flutter/skills|skills/flutter-setup-declarative-routing"
  "flutter/skills|skills/flutter-setup-localization"
  "flutter/skills|skills/flutter-use-http-package"

  # github/awesome-copilot
  "github/awesome-copilot|skills/draw-io-diagram-generator"
  "github/awesome-copilot|skills/gdpr-compliant"
  "github/awesome-copilot|skills/gh-cli"

  # heygen-com/hyperframes
  "heygen-com/hyperframes|skills/animejs"
  "heygen-com/hyperframes|skills/contribute-catalog"
  "heygen-com/hyperframes|skills/css-animations"
  "heygen-com/hyperframes|skills/gsap"
  "heygen-com/hyperframes|skills/hyperframes"
  "heygen-com/hyperframes|skills/hyperframes-cli"
  "heygen-com/hyperframes|skills/hyperframes-media"
  "heygen-com/hyperframes|skills/hyperframes-registry"
  "heygen-com/hyperframes|skills/lottie"
  "heygen-com/hyperframes|skills/remotion-to-hyperframes"
  "heygen-com/hyperframes|skills/tailwind"
  "heygen-com/hyperframes|skills/three"
  "heygen-com/hyperframes|skills/typegpu"
  "heygen-com/hyperframes|skills/waapi"
  "heygen-com/hyperframes|skills/website-to-hyperframes"

  # jablonkai/agent-tools
  "jablonkai/agent-tools|skills/code-analyzer"
  "jablonkai/agent-tools|skills/duv"
  "jablonkai/agent-tools|skills/emu-branding"
  "jablonkai/agent-tools|skills/github-commit-pr"
  "jablonkai/agent-tools|skills/github-do-issue"
  "jablonkai/agent-tools|skills/github-fix-action-error"
  "jablonkai/agent-tools|skills/github-issues"
  "jablonkai/agent-tools|skills/markitdown"

  # kepano/obsidian-skills
  "kepano/obsidian-skills|skills/defuddle"
  "kepano/obsidian-skills|skills/json-canvas"
  "kepano/obsidian-skills|skills/obsidian-bases"
  "kepano/obsidian-skills|skills/obsidian-cli"
  "kepano/obsidian-skills|skills/obsidian-markdown"

  # microsoft/playwright-cli
  "microsoft/playwright-cli|skills/playwright-cli"

  # PicsArt/gen-ai-skills
  "PicsArt/gen-ai-skills|skills/agency-brand-scoping"
  "PicsArt/gen-ai-skills|skills/agency-client-handoff"
  "PicsArt/gen-ai-skills|skills/agency-multi-brand-pack"
  "PicsArt/gen-ai-skills|skills/agency-pitch-mockups"
  "PicsArt/gen-ai-skills|skills/dev-app-assets"
  "PicsArt/gen-ai-skills|skills/dev-avatar-service"
  "PicsArt/gen-ai-skills|skills/dev-screenshot-beautifier"
  "PicsArt/gen-ai-skills|skills/enterprise-brand-governor"
  "PicsArt/gen-ai-skills|skills/enterprise-pinned-registry"
  "PicsArt/gen-ai-skills|skills/enterprise-press-batch"
  "PicsArt/gen-ai-skills|skills/gen-ai-explainer"
  "PicsArt/gen-ai-skills|skills/gen-ai-persona-creation"
  "PicsArt/gen-ai-skills|skills/gen-ai-use"
  "PicsArt/gen-ai-skills|skills/marketer-ad-variant-factory"
  "PicsArt/gen-ai-skills|skills/marketer-localize-campaign"
  "PicsArt/gen-ai-skills|skills/multi-channel-bundle"
  "PicsArt/gen-ai-skills|skills/product-photo-studio"
  "PicsArt/gen-ai-skills|skills/prosumer-headshot-studio"
  "PicsArt/gen-ai-skills|skills/text-to-visual"

  # upstash/context7
  "upstash/context7|skills/context7-cli"
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
C_SDKMAN=$'\033[38;5;99m'      # violet (Kotlin #7F52FF)
C_RUST=$'\033[38;5;166m'       # rust orange (#CE422B)
C_PYTHON=$'\033[38;5;220m'     # python yellow
C_GITHUB=$'\033[38;5;141m'     # purple/violet
C_SKILLS=$'\033[38;5;51m'      # cyan (agent-tools)
C_MO=$'\033[38;5;201m'         # magenta
C_APPLE=$'\033[38;5;250m'      # silver/gray
C_INIT=$'\033[38;5;48m'        # spring green (bootstrap)

# ---------- step registry ----------
# Ordered list of steps. Format: "ID|COLOR_VAR|TITLE"
# The ID is what the user passes to --only/--skip (and as positional args).
# Each ID maps to a function named do_<id> (hyphens → underscores).
STEPS=(
  "brew|C_HOMEBREW|Homebrew: update + upgrade + cleanup"
  "android|C_ANDROID|Android: CLI update + SDK packages update"
  "android-skills|C_ANDROID|Android skills: install/update via android skills add"
  "flutter|C_FLUTTER|Flutter: upgrade"
  "sdk|C_SDKMAN|SDKMAN: selfupdate + update + upgrade + install/upgrade + warm-up kotlintoolchain"
  "rust|C_RUST|Rust toolchain: rustup update"
  "pipx|C_PYTHON|pipx: upgrade all packages"
  "gh-ext|C_GITHUB|GitHub CLI extensions: upgrade all"
  "skills|C_SKILLS|Agent skills: install/update via gh skill"
  "claude-md|C_SKILLS|Global CLAUDE.md: sync from jablonkai/agent-tools"
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
  printf '%s$ %s%s\n' "${DIM}" "$*" "${RESET}"
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
  printf '%s$ %s%s\n' "${DIM}" "$*" "${RESET}"
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
    # Newer Homebrew prompts for confirmation before some upgrades (e.g. casks).
    # Feed `yes` on stdin so any such prompt is auto-accepted and the step runs
    # unattended. Mirrors the sdk_auto pattern in do_sdk. brew reads password /
    # sudo prompts from the tty, not stdin, so this only answers y/N questions.
    brew_auto() { yes 2>/dev/null | brew "$@"; }

    # --verbose so fetched taps / up-to-date lines are always visible.
    run "brew update"  brew_auto update --verbose
    run "brew upgrade" brew_auto upgrade --verbose
    run "brew cleanup --prune" brew_auto cleanup --prune=all
  else
    skip "brew" "not installed"
  fi
}

do_android() {
  if have android; then
    run "android update" android update
    # `android sdk update` with no package name updates every installed SDK
    # package (platform-tools, build-tools, platforms, emulator, …) to latest.
    run "android sdk update" android sdk update
  else
    skip "android" "not installed"
  fi
}

do_android_skills() {
  if ! have android; then
    skip "android skills" "android not installed"
    return
  fi

  local target agents=""
  for target in "${SKILL_TARGETS[@]}"; do
    agents+="${agents:+,}$target"
  done

  if [[ -z "$agents" ]]; then
    skip "android skills add" "no targets in SKILL_TARGETS"
    return
  fi

  local skill
  for skill in "${ANDROID_SKILLS[@]}"; do
    run "android skills add $skill → $agents" \
      android skills add "$skill" --agent="$agents"
  done
}

do_flutter() {
  if have flutter; then
    run "flutter upgrade --force" flutter upgrade --force
  else
    skip "flutter" "not installed"
  fi
}

do_sdk() {
  local init="$HOME/.sdkman/bin/sdkman-init.sh"
  if [[ ! -s "$init" ]]; then
    skip "sdk" "SDKMAN not installed"
    return
  fi

  # `sdk` is a shell function provided by SDKMAN's init script, not a binary,
  # so source it before use (the `have` check wouldn't find it otherwise).
  # SDKMAN's init and subcommand scripts reference unset vars (e.g.
  # $ZSH_VERSION), which abort under `set -u`. Relax nounset for the whole
  # SDKMAN section and restore it before returning.
  set +u
  # shellcheck disable=SC1090
  source "$init"
  if ! declare -F sdk >/dev/null; then
    set -u
    skip "sdk" "SDKMAN init did not provide the sdk function"
    return
  fi

  # SDKMAN re-sources etc/config (sdkman_auto_answer=false) on every `sdk`
  # call, so an env override won't stick. Feed `yes` on stdin instead so any
  # confirmation prompt is auto-accepted and the step runs unattended.
  sdk_auto() { yes 2>/dev/null | sdk "$@"; }

  run "sdk selfupdate"              sdk_auto selfupdate          # update SDKMAN itself
  run "sdk update"                  sdk_auto update              # refresh candidate metadata
  run "sdk upgrade"                 sdk_auto upgrade             # upgrade all installed candidates
  run "sdk install kotlintoolchain" sdk_auto install kotlintoolchain
  # kotlintoolchain is a "hidden" candidate (absent from `sdk list candidates`),
  # so the no-arg `sdk upgrade` above doesn't reliably cover it — upgrade it
  # explicitly. No-op ("up-to-date") when already on the latest version.
  run "sdk upgrade kotlintoolchain"  sdk_auto upgrade kotlintoolchain

  # Warm up the Kotlin toolchain. The `kotlintoolchain` candidate only installs
  # a thin `kotlin` launcher; the real toolchain (CLI dist + JRE) is downloaded
  # lazily on the first `kotlin` invocation. Trigger that download now via
  # `kotlin --version` so the user's first real use isn't blocked on it.
  # No-op (prints the version from cache) once the toolchain is already present.
  if have kotlin; then
    run "kotlin toolchain warm-up" kotlin --version
  else
    skip "kotlin toolchain warm-up" "kotlin not on PATH"
  fi

  set -u
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
  local known_dir common_dir
  local placement_args

  for entry in "${SKILLS[@]}"; do
    IFS='|' read -r repo path <<< "$entry"
    skill_name="${path##*/}"
    known_dir=""
    common_dir=""

    for target in "${SKILL_TARGETS[@]}"; do
      target_dir=$(agent_skills_dir "$target") || {
        echo "unknown SKILL_TARGETS entry: $target" >&2
        continue
      }

      # `common` (~/.agents/skills) is a custom directory for `gh skill`,
      # so use `--dir` together with `--agent universal` (the matching agent
      # name). Other targets are known agents — use `--agent --scope`.
      if [[ "$target" == "common" ]]; then
        placement_args=(--agent universal --dir "$target_dir")
      else
        placement_args=(--agent "$target" --scope user)
      fi

      if [[ ! -f "$target_dir/$skill_name/SKILL.md" ]]; then
        # --force overwrites without prompting. A skill whose upstream
        # frontmatter is broken fails install (leaving a partial dir with no
        # SKILL.md), so the guard above re-runs install on every pass; without
        # --force that re-run hangs on an interactive "Overwrite? (y/N)" prompt
        # in unattended runs. The failure is still recorded in the summary.
        run "gh skill install $skill_name → $target" \
          gh skill install "$repo" "$path" "${placement_args[@]}" --force
      else
        skip "gh skill install $skill_name → $target" "already installed, will update" "no_summary"
        if [[ "$target" == "common" ]]; then
          common_dir="$target_dir"
        else
          [[ -z "$known_dir" ]] && known_dir="$target_dir"
        fi
      fi
    done

    # `gh skill update --all` scans known agent host dirs automatically;
    # for the `common` custom dir we need an explicit `--dir` update.
    if [[ -n "$known_dir" ]]; then
      run_if_changed "gh skill update $skill_name" "$known_dir/$skill_name" \
        gh skill update "$skill_name" --all
    fi
    if [[ -n "$common_dir" ]]; then
      run_if_changed "gh skill update $skill_name → common" "$common_dir/$skill_name" \
        gh skill update "$skill_name" --dir "$common_dir" --all
    fi
  done
}

# Syncs the global Claude instruction file (~/.claude/CLAUDE.md) from the
# agent-tools repo, where instructions/CLAUDE.md is the source of truth.
# Uses 'gh' for authenticated access (works with private repos).
# Downloads to a temp file first so a failed fetch never truncates the
# existing global file.
do_claude_md() {
  if ! have gh; then
    skip "global CLAUDE.md" "gh (GitHub CLI) not installed"
    return
  fi

  local dest="$HOME/.claude/CLAUDE.md"

  sync_claude_md() {
    local tmp
    tmp=$(mktemp) || return 1
    if gh api repos/jablonkai/agent-tools/contents/instructions/CLAUDE.md \
         --jq '.content' | base64 -d > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
      mkdir -p "$(dirname "$dest")"
      mv "$tmp" "$dest"
    else
      rm -f "$tmp"
      return 1
    fi
  }

  run "global CLAUDE.md → $dest" sync_claude_md
}

do_cleanup() {
  cleanup_skip() {
    skip "$1" "$2" "no_summary"
  }

  # npm cache cleanup
  if have npm; then
    run "npm cache clean" npm cache clean --force
  else
    cleanup_skip "npm cache clean" "npm not installed"
  fi

  # pnpm cache cleanup
  if have pnpm; then
    run "pnpm store prune" pnpm store prune
  else
    cleanup_skip "pnpm store prune" "pnpm not installed"
  fi

  # Yarn cache cleanup
  if have yarn; then
    run "yarn cache clean" yarn cache clean
  else
    cleanup_skip "yarn cache clean" "yarn not installed"
  fi

  # Deno cache cleanup
  if [[ -d "$HOME/.deno" ]]; then
    run "rm -rf ~/.deno" rm -rf "$HOME"/.deno
  else
    cleanup_skip "deno cache cleanup" "deno not found"
  fi

  # Bun cache cleanup
  if [[ -d "$HOME/.bun/install/cache" ]]; then
    run "rm -rf ~/.bun/install/cache" rm -rf "$HOME"/.bun/install/cache
  else
    cleanup_skip "bun cache cleanup" "bun cache not found"
  fi

  # Playwright cache cleanup
  if [[ -d "$HOME/.cache/ms-playwright" ]]; then
    run "rm -rf ~/.cache/ms-playwright" rm -rf "$HOME"/.cache/ms-playwright
  else
    cleanup_skip "playwright cache cleanup" "playwright cache not found"
  fi

  # pip cache cleanup
  if have pip; then
    run "pip cache purge" pip cache purge
  else
    cleanup_skip "pip cache purge" "pip not installed"
  fi

  # Poetry cache cleanup
  if have poetry; then
    run "poetry cache clear" poetry cache clear --all
  else
    cleanup_skip "poetry cache clear" "poetry not installed"
  fi

  # Gem cache cleanup
  if have gem; then
    run "gem cleanup" gem cleanup
  else
    cleanup_skip "gem cleanup" "gem not installed"
  fi

  # Maven cache cleanup
  if [[ -d "$HOME/.m2/repository" ]]; then
    run "rm -rf ~/.m2/repository" rm -rf "$HOME"/.m2/repository
  else
    cleanup_skip "maven cache cleanup" "maven cache not found"
  fi

  # Gradle cache cleanup
  if [[ -d "$HOME/.gradle/caches" ]]; then
    # Stop gradle daemon if running (prevents lock issues)
    if have gradle; then
      gradle --stop 2>/dev/null || true
    fi
    run "rm -rf ~/.gradle/caches" rm -rf "$HOME"/.gradle/caches
  else
    cleanup_skip "gradle cache cleanup" "gradle cache not found"
  fi

  # Cargo cache cleanup
  if [[ -d "$HOME/.cargo/registry/cache" ]]; then
    run "rm -rf ~/.cargo/registry/cache" rm -rf "$HOME"/.cargo/registry/cache
  else
    cleanup_skip "cargo cache cleanup" "cargo cache not found"
  fi

  # Go cache cleanup
  if [[ -d "$HOME/.cache/go-build" ]]; then
    run "rm -rf ~/.cache/go-build" rm -rf "$HOME"/.cache/go-build
  else
    cleanup_skip "go cache cleanup" "go cache not found"
  fi

  # CocoaPods cache cleanup
  if [[ -d "$HOME/.cocoapods/repos" ]]; then
    run "rm -rf ~/.cocoapods/repos" rm -rf "$HOME"/.cocoapods/repos
  else
    cleanup_skip "cocoapods cache cleanup" "cocoapods not found"
  fi

  # Xcode Derived Data cleanup
  if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
    run "rm -rf ~/Library/Developer/Xcode/DerivedData" rm -rf "$HOME"/Library/Developer/Xcode/DerivedData
  else
    cleanup_skip "xcode derived data cleanup" "xcode not found"
  fi

  # .NET cache cleanup
  if have dotnet; then
    run "dotnet nuget locals all --clear" dotnet nuget locals all --clear
  else
    cleanup_skip "dotnet cache cleanup" "dotnet not installed"
  fi

  # SwiftPM cache cleanup
  if [[ -d "$HOME/.swiftpm" ]]; then
    run "rm -rf ~/.swiftpm" rm -rf "$HOME"/.swiftpm
  else
    cleanup_skip "swiftpm cache cleanup" "swiftpm not found"
  fi

  # JetBrains IDE caches cleanup
  if [[ -d "$HOME/.cache/JetBrains" ]]; then
    run "rm -rf ~/.cache/JetBrains" rm -rf "$HOME"/.cache/JetBrains
  else
    cleanup_skip "jetbrains cache cleanup" "jetbrains cache not found"
  fi

  # Android Studio cache cleanup
  if [[ -d "$HOME/Library/Caches/Google" ]]; then
    run "rm -rf ~/Library/Caches/Google/AndroidStudio*" rm -rf "$HOME"/Library/Caches/Google/AndroidStudio*
  else
    cleanup_skip "android studio cache cleanup" "android studio not found"
  fi

  # Bazel cache cleanup
  if [[ -d "$HOME/.bazel" ]]; then
    run "rm -rf ~/.bazel" rm -rf "$HOME"/.bazel
  else
    cleanup_skip "bazel cache cleanup" "bazel not found"
  fi

  # Pants cache cleanup
  if [[ -d "$HOME/.cache/pants" ]]; then
    run "rm -rf ~/.cache/pants" rm -rf "$HOME"/.cache/pants
  else
    cleanup_skip "pants cache cleanup" "pants not found"
  fi

  # Docker cache cleanup
  if have docker; then
    run "docker system prune -f" docker system prune -f
  else
    cleanup_skip "docker system prune" "docker not installed"
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

# ---------- init / bootstrap ----------
# `update-all init` installs the full toolchain from scratch, then falls
# through to a normal update run (see RUN_INIT handling below). Every
# installer is idempotent: tools already present are skipped, so re-running
# `init` on a provisioned machine is safe.

# Raw installer commands. Each is wrapped in a function because run() executes
# a command via "$@" (not a shell pipeline), so the curl|bash one-liners and
# env-prefixed invocations need to live inside a function body.
install_homebrew()    { NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }
install_android_cli() {
  # Google publishes a per-platform install.sh; it moves the binary into
  # /usr/local/bin (may prompt for sudo on macOS).
  local os arch
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64)  arch=x86_64 ;;
    *)             arch=$(uname -m) ;;
  esac
  curl -fsSL "https://dl.google.com/android/cli/latest/${os}_${arch}/install.sh" | bash
}
install_gen_ai()      { curl -fsSL https://picsart.com/gen-ai-cli/install.sh | bash; }
install_sdkman()      { curl -fsSL https://get.sdkman.io | bash; }

# Where the Flutter SDK gets extracted (matches the existing machine layout).
FLUTTER_DIR="$HOME/Utils/flutter"

# Manual Flutter install per https://docs.flutter.dev/install/manual — download
# the official stable zip and extract it (no Homebrew). Picks the right archive
# for the host arch from Flutter's release manifest. jq is pulled via brew if
# missing; brew is already present by the time this runs.
install_flutter() {
  local arch json base archive url tmp
  case "$(uname -m)" in
    arm64|aarch64) arch=arm64 ;;
    *)             arch=x64 ;;
  esac
  have jq || brew install jq >/dev/null 2>&1 || true
  json=$(curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json) || return 1
  base=$(printf '%s' "$json" | jq -r '.base_url')
  archive=$(printf '%s' "$json" | jq -r --arg a "$arch" \
    '.current_release.stable as $h | .releases[] | select(.hash==$h and .dart_sdk_arch==$a) | .archive' | head -1)
  [[ -n "$base" && -n "$archive" && "$archive" != "null" ]] || return 1
  url="$base/$archive"
  tmp=$(mktemp -d) || return 1
  if ! curl -fsSL "$url" -o "$tmp/flutter.zip"; then rm -rf "$tmp"; return 1; fi
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  # The zip already contains a top-level flutter/ dir.
  if ! unzip -q "$tmp/flutter.zip" -d "$(dirname "$FLUTTER_DIR")"; then rm -rf "$tmp"; return 1; fi
  rm -rf "$tmp"
}

# Append a line to ~/.zprofile once (idempotent), so a new shell keeps the PATH.
add_to_zprofile() {  # line
  local line="$1" prof="$HOME/.zprofile"
  grep -qsF -- "$line" "$prof" 2>/dev/null && return 0
  printf '%s\n' "$line" >> "$prof"
}

# Printed at the very end of an `init` run: the installers above don't log you
# in, so list the tools that still need interactive authentication.
print_auth_reminder() {
  echo
  hr "$C_INIT"
  printf '%s%s⚠ Manual authentication still required%s\n' "${BOLD}" "$C_INIT" "${RESET}"
  hr "$C_INIT"
  printf '%sThe installers do not sign you in. Authenticate these before first use:%s\n' "${DIM}" "${RESET}"
  printf '  %-14s %s\n' "gh"            "gh auth login"
  printf '  %-14s %s\n' "Claude Code"   "claude  → then /login"
  printf '  %-14s %s\n' "Codex"         "codex  → sign in on first run"
  printf '  %-14s %s\n' "Antigravity"   "agy  → sign in on first run"
  printf '  %-14s %s\n' "Cursor"        "cursor-agent login"
  printf '  %-14s %s\n' "Kiro"          "kiro-cli  → sign in on first run"
  printf '  %-14s %s\n' "Copilot"       "copilot  → GitHub sign-in on first run"
  printf '  %-14s %s\n' "OpenCode"      "opencode auth login"
  printf '  %-14s %s\n' "Kilo"          "kilo  → sign in on first run"
  printf '  %-14s %s\n' "Picsart gen-ai" "gen-ai login"
  printf '  %-14s %s\n' "context7"      "ctx7  → set your Context7 API key if prompted"
}

# Install $cmd via $installer only if missing; record via run()/skip().
ensure_cmd() {  # cmd label installer-cmd [args...]
  local cmd="$1" label="$2"; shift 2
  if have "$cmd"; then
    skip "install $label" "already installed"
  else
    run "install $label" "$@"
    hash -r 2>/dev/null
  fi
}

ensure_brew_formula() {  # cmd formula
  local cmd="$1" formula="$2"
  if ! have brew; then skip "install $formula" "brew not available"; return; fi
  if have "$cmd"; then skip "install $formula" "already installed"; return; fi
  run "brew install $formula" brew install "$formula"
  hash -r 2>/dev/null
}

ensure_brew_cask() {  # cmd cask
  local cmd="$1" cask="$2"
  if ! have brew; then skip "install $cask" "brew not available"; return; fi
  if have "$cmd"; then skip "install $cask" "already installed"; return; fi
  run "brew install --cask $cask" brew install --cask "$cask"
  hash -r 2>/dev/null
}

do_init() {
  # Prepend the dirs installers drop binaries into so the `have` checks below
  # (and the trailing update-all run) can see them this session.
  export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$FLUTTER_DIR/bin:$PATH"

  # 0. Xcode Command Line Tools — provides git + compilers and is a hard
  #    prerequisite for Homebrew, so install it first. `xcode-select --install`
  #    opens a GUI dialog and returns immediately; the rest proceeds once done.
  if xcode-select -p >/dev/null 2>&1; then
    skip "install Xcode Command Line Tools" "already installed"
  else
    run "install Xcode Command Line Tools" xcode-select --install
  fi

  # 1. Homebrew — base package manager for most tools below.
  ensure_cmd brew "Homebrew" install_homebrew
  # Load brew into this shell so the formula/cask installs can run.
  if have brew; then
    eval "$(brew shellenv)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  hash -r 2>/dev/null

  # 2. Android CLI, then initialize its environment (skills etc).
  ensure_cmd android "Android CLI" install_android_cli
  if have android; then
    run "android init" android init
  else
    skip "android init" "android not installed"
  fi

  # 2b. Android SDK — use the android CLI's own package manager to pull the core
  #     SDK components: platform-tools (adb/fastboot), the emulator, a recent
  #     platform, and matching build-tools. `android sdk install` defaults each
  #     package to its latest version and is idempotent (already-installed
  #     packages are no-ops), so re-running is safe. Bump the API level here when
  #     a newer stable platform is needed.
  if have android; then
    run "android sdk install (platform-tools, emulator, platform, build-tools)" \
      android sdk install platform-tools emulator platforms/android-35 build-tools/35.0.0
  else
    skip "android sdk install" "android not installed"
  fi

  # 3. Core tooling via Homebrew. `mo` is tw93's mole (shadows core/mole).
  #    node ships npm (needed for the ctx7 install below); pipx backs
  #    markitdown; uv is general Python tooling.
  ensure_brew_formula node node          # node + npm
  ensure_brew_formula pipx pipx
  ensure_brew_formula uv   uv
  ensure_brew_formula gh   gh
  ensure_brew_formula mo   tw93/tap/mole

  # git — always install Homebrew's git, even though the Command Line Tools
  # already provide one. Keyed on brew's own install state (not `have git`,
  # which the CLT git satisfies); brew is earlier in PATH via `brew shellenv`,
  # so its git takes precedence over /usr/bin/git once installed.
  if ! have brew; then
    skip "install git" "brew not available"
  elif brew list --formula git >/dev/null 2>&1; then
    skip "brew install git" "already installed"
  else
    run "brew install git" brew install git
    hash -r 2>/dev/null
  fi

  # 4. Agent CLIs (delegation fleet from CLAUDE.md) — all available via brew.
  #    ensure_brew_cask/formula take the bare package name as the 2nd arg.
  ensure_brew_cask    claude       claude-code        # Claude Code CLI
  ensure_brew_cask    copilot      copilot-cli        # GitHub Copilot CLI
  ensure_brew_cask    codex        codex              # OpenAI Codex CLI
  ensure_brew_cask    agy          antigravity-cli    # Google Antigravity CLI
  ensure_brew_cask    cursor-agent cursor-cli         # Cursor CLI
  ensure_brew_formula opencode     opencode           # OpenCode CLI
  ensure_brew_formula kilo         kilo-org/tap/kilo  # Kilo Code CLI
  ensure_brew_cask    kiro-cli     kiro-cli           # Kiro CLI

  # 5. Extra CLIs.
  ensure_cmd gen-ai "Picsart gen-ai CLI" install_gen_ai
  if have npm; then
    ensure_cmd ctx7 "context7 CLI (ctx7)" npm install -g ctx7@latest
  else
    skip "install context7 CLI (ctx7)" "npm not installed"
  fi
  # markitdown — required by the repo's own markitdown skill (a pipx package).
  if have pipx; then
    ensure_cmd markitdown "markitdown[all]" pipx install 'markitdown[all]'
  else
    skip "install markitdown[all]" "pipx not installed"
  fi

  # 6. Flutter SDK — manual install (downloaded zip, not Homebrew). Add its bin
  #    to PATH for this session and persist it in ~/.zprofile.
  ensure_cmd flutter "Flutter SDK (manual)" install_flutter
  if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
    export PATH="$FLUTTER_DIR/bin:$PATH"
    add_to_zprofile "export PATH=\"\$HOME/Utils/flutter/bin:\$PATH\""
    hash -r 2>/dev/null
  fi

  # 7. SDKMAN provides `sdk`; the trailing update-all `sdk` step then runs
  #    `sdk install kotlintoolchain`, so the Kotlin toolchain lands there.
  if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    skip "install SDKMAN" "already installed"
  else
    run "install SDKMAN" install_sdkman
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

${BOLD}Bootstrap:${RESET}
  init                  Install the full toolchain from scratch, then run a
                        normal update. Installs (idempotently): Xcode Command
                        Line Tools, Homebrew, node, git, pipx, uv, Android CLI +
                        'android init' + Android SDK (platform-tools, emulator,
                        platform, build-tools), gh, mo, the agent CLIs (claude, copilot,
                        codex, agy, cursor, opencode, kilo, kiro), gen-ai, ctx7,
                        markitdown, Flutter (manual), and SDKMAN (kotlintoolchain
                        lands via the trailing sdk step). Prints an auth reminder
                        at the end for tools that need an interactive login.

${BOLD}Available steps:${RESET}
$(for entry in "${STEPS[@]}"; do
    IFS='|' read -r id color title <<< "$entry"
    printf '  %-12s %s\n' "$id" "$title"
  done)

${BOLD}Examples:${RESET}
  # Bootstrap a brand-new machine, then update everything
  $(basename "$0") init

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

# `init` is a bootstrap subcommand, not a step id. Pull it out before parsing
# so it isn't validated against the step registry. After init runs, the
# remaining args (usually none) drive a normal update.
RUN_INIT=0
init_filtered=()
for arg in "$@"; do
  if [[ "$arg" == "init" ]]; then RUN_INIT=1; else init_filtered+=("$arg"); fi
done
set -- ${init_filtered[@]+"${init_filtered[@]}"}

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

# ---------- sudo priming ----------
# The mo (mole) cleanup steps shell out to `sudo` internally to remove
# system-owned caches. Prompt for the password once at the very start and keep
# the sudo timestamp warm in the background, so those steps run unattended at
# the end of a long run instead of blocking on (or timing out) a mid-run prompt.
SUDO_KEEPALIVE_PID=""

prime_sudo() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] && return 0          # already root
  have sudo || { skip "sudo priming" "sudo not available"; return 0; }
  printf '%s%s🔑 Password needed up front for the mo cleanup steps at the end.%s\n' \
    "${BOLD}" "${C_MO}" "${RESET}"
  if ! sudo -v; then
    printf '%s⚠ Could not cache sudo credentials; mo steps may prompt later.%s\n' \
      "${YELLOW}" "${RESET}"
    return 1
  fi
  # Refresh the cached credential every 60s (sudo's default timeout is 5min)
  # until this script exits, so it's still valid when the mo steps run.
  ( while true; do sudo -n true 2>/dev/null; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
  [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
}

# ---------- run ----------

# Prompt for the password up front if any mo step is actually going to run.
if have mo && { should_run "mo-clean" || should_run "mo-optimize"; }; then
  prime_sudo
  trap stop_sudo_keepalive EXIT
fi

# Bootstrap first when `init` was given, then fall through to the normal run.
if ((RUN_INIT)); then
  step "$C_INIT" "Init: install the full toolchain from scratch"
  do_init
fi

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

# After an `init` run, remind about the logins the installers can't do.
if ((RUN_INIT)); then
  print_auth_reminder
fi
