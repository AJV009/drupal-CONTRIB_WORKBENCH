#!/usr/bin/env bash
# install.sh — interactive setup for the Drupal Contrib Workbench.
#
# Safe to re-run: existing values are offered as defaults and files are
# only overwritten when you provide a new value.
#
# Writes (all gitignored):
#   anthropic.key
#   git.drupalcode.org.key
#   CLAUDE.local.md
#   .workbench/config.env
#   scripts/drupalorg.phar  (downloaded from GitHub releases)

set -euo pipefail

WORKBENCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$WORKBENCH"

# ---------------------------------------------------------------------------
# Pretty printing
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_RESET=$'\033[0m'
else
  C_BOLD=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

bold() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
ok()   { printf '  %s[ok]%s   %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '  %s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()  { printf '  %s[err]%s  %s\n' "$C_RED" "$C_RESET" "$*"; }
note() { printf '  %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }

# ---------------------------------------------------------------------------
# Prompt helpers
# ---------------------------------------------------------------------------
# Plain prompt with optional default.
ask() {
  local __out="$1" prompt="$2" default="${3:-}" input
  if [[ -n "$default" ]]; then
    read -rp "  $prompt [$default]: " input || true
    printf -v "$__out" '%s' "${input:-$default}"
  else
    read -rp "  $prompt: " input || true
    printf -v "$__out" '%s' "$input"
  fi
}

# Secret prompt (no echo). If a default exists, empty input keeps it.
ask_secret() {
  local __out="$1" prompt="$2" default="${3:-}" input
  if [[ -n "$default" ]]; then
    read -rsp "  $prompt [press enter to keep existing]: " input || true
    echo
    printf -v "$__out" '%s' "${input:-$default}"
  else
    read -rsp "  $prompt: " input || true
    echo
    printf -v "$__out" '%s' "$input"
  fi
}

yes_no() {
  local __out="$1" prompt="$2" default="${3:-N}" input
  read -rp "  $prompt [y/N]: " input || true
  input="${input:-$default}"
  case "$input" in
    y|Y|yes|YES|Yes) printf -v "$__out" '1' ;;
    *)               printf -v "$__out" '0' ;;
  esac
}

# ---------------------------------------------------------------------------
# Load existing values as defaults (re-run friendly)
# ---------------------------------------------------------------------------
EXISTING_USERNAME=""
EXISTING_TUI="0"
CONFIG_FILE="$WORKBENCH/.workbench/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  EXISTING_USERNAME="${DRUPAL_USERNAME:-}"
  EXISTING_TUI="${WORKBENCH_TUI:-0}"
fi

EXISTING_ANTHROPIC=""
[[ -f "$WORKBENCH/anthropic.key" ]] && EXISTING_ANTHROPIC="$(cat "$WORKBENCH/anthropic.key")"

EXISTING_GITLAB=""
[[ -f "$WORKBENCH/git.drupalcode.org.key" ]] && EXISTING_GITLAB="$(cat "$WORKBENCH/git.drupalcode.org.key")"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
printf '%s\n' "$C_BOLD"
cat <<'EOF'
Drupal Contrib Workbench — interactive install
EOF
printf '%s' "$C_RESET"
note "Workbench root: $WORKBENCH"
note "Safe to re-run: blank answers keep existing values."

# ---------------------------------------------------------------------------
# 1. drupal.org username
# ---------------------------------------------------------------------------
bold "1. drupal.org username"
note "Used in CLAUDE.local.md so the agent knows whose d.o account to act as."
ask DO_USERNAME "drupal.org username" "$EXISTING_USERNAME"
if [[ -z "$DO_USERNAME" ]]; then
  err "username is required"
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Anthropic API key (optional — only for AI-module testing)
# ---------------------------------------------------------------------------
bold "2. Anthropic API key (optional)"
note "Used only by the AI Module Testing flow described in CLAUDE.md."
note "Leave blank to skip — the rest of the workbench works without it."
ask_secret ANTHROPIC_KEY "Anthropic API key (sk-ant-...)" "$EXISTING_ANTHROPIC"

# ---------------------------------------------------------------------------
# 3. drupal.org GitLab token (required for MR/pipeline features)
# ---------------------------------------------------------------------------
bold "3. drupal.org GitLab token"
note "Used to fetch MR notes, pipeline status, and CI logs from"
note "git.drupalcode.org. Without it, MR-related features silently degrade."
note "Create one at: https://git.drupalcode.org/-/user_settings/personal_access_tokens"
note "Minimum scopes: read_api, read_repository."
ask_secret GITLAB_TOKEN "GitLab personal access token" "$EXISTING_GITLAB"

# ---------------------------------------------------------------------------
# 4. tui-browser integration (opt-in)
# ---------------------------------------------------------------------------
bold "4. Optional integrations"
note "tui-browser is a separate terminal UI that reads tui.json to list the"
note "issues you are working on. Skip unless you specifically use it."
TUI_DEFAULT="N"
[[ "$EXISTING_TUI" == "1" ]] && TUI_DEFAULT="y"
yes_no WORKBENCH_TUI "Enable tui-browser integration" "$TUI_DEFAULT"

# ---------------------------------------------------------------------------
# 5. Write files
# ---------------------------------------------------------------------------
bold "Writing configuration"
mkdir -p "$WORKBENCH/.workbench"

if [[ -n "$ANTHROPIC_KEY" ]]; then
  printf '%s\n' "$ANTHROPIC_KEY" > "$WORKBENCH/anthropic.key"
  chmod 600 "$WORKBENCH/anthropic.key"
  ok "wrote anthropic.key (chmod 600)"
else
  note "skipped anthropic.key (no value provided)"
fi

if [[ -n "$GITLAB_TOKEN" ]]; then
  printf '%s\n' "$GITLAB_TOKEN" > "$WORKBENCH/git.drupalcode.org.key"
  chmod 600 "$WORKBENCH/git.drupalcode.org.key"
  ok "wrote git.drupalcode.org.key (chmod 600)"
else
  note "skipped git.drupalcode.org.key (no value provided)"
fi

cat > "$CONFIG_FILE" <<EOF
# Generated by install.sh — safe to edit by hand.
# Sourced by drupal-issue.sh at startup.
DRUPAL_USERNAME=$DO_USERNAME
WORKBENCH_TUI=$WORKBENCH_TUI
EOF
ok "wrote .workbench/config.env"

cat > "$WORKBENCH/CLAUDE.local.md" <<EOF
# Local project context

This file is generated by \`install.sh\` and is gitignored.

## User

- **$DO_USERNAME** on drupal.org is the person running this Claude Code
  setup and all associated commands/skills. Treat this user as the
  contributor of record unless the prompt says otherwise.
EOF
ok "wrote CLAUDE.local.md"

# ---------------------------------------------------------------------------
# 6. Download drupalorg.phar
# ---------------------------------------------------------------------------
bold "drupalorg-cli phar"
PHAR="$WORKBENCH/scripts/drupalorg.phar"
PHAR_URL="https://github.com/mglaman/drupalorg-cli/releases/latest/download/drupalorg.phar"
if [[ -f "$PHAR" ]]; then
  ok "scripts/drupalorg.phar already present — leaving alone"
  note "delete and re-run install.sh to fetch the latest release"
else
  if command -v curl &>/dev/null; then
    if curl -fsSL -o "$PHAR.tmp" "$PHAR_URL"; then
      mv "$PHAR.tmp" "$PHAR"
      chmod +x "$PHAR"
      ok "downloaded scripts/drupalorg.phar from GitHub releases"
    else
      rm -f "$PHAR.tmp"
      warn "could not fetch $PHAR_URL"
      warn "download it manually and place at $PHAR"
    fi
  else
    warn "curl not found; cannot auto-download drupalorg.phar"
    warn "grab it from $PHAR_URL"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Dependency check
# ---------------------------------------------------------------------------
bold "Dependency check"
# required: exit warning if missing
# optional: just note
_check() {
  local cmd="$1" tier="$2" purpose="$3"
  if command -v "$cmd" &>/dev/null; then
    ok "$cmd found — $purpose"
  elif [[ "$tier" == "required" ]]; then
    warn "$cmd MISSING (required) — $purpose"
  else
    note "$cmd missing (optional) — $purpose"
  fi
}
_check claude        required "Claude Code CLI"
_check ddev          required "Drupal container environments"
_check jq            required "JSON processing"
_check uuidgen       required "session UUID generation"
_check tmux          required "session management"
_check python3       required "scripts/lib/data helpers"
_check php           optional "PHAR runner (DDEV provides php inside containers)"
_check bd            optional "beads cross-issue memory"
_check dolt          optional "SQL backing for bd"
_check uv            optional "temporary Python venvs"
_check agent-browser optional "browser automation for UI verification"

# ---------------------------------------------------------------------------
# 8. Next steps
# ---------------------------------------------------------------------------
bold "Setup complete"
cat <<EOF

Next steps:
  1. (Optional but recommended) Initialize beads in this checkout:
       bd init
       bd setup claude
       bd config set backup.git-push false
       bd config set dolt.auto-push false
       bd config set dolt.auto-pull false

  2. Run your first issue:
       ./drupal-issue.sh https://www.drupal.org/i/<issue-id>

  3. Re-run this installer any time to update values:
       ./install.sh

Files written by this installer are gitignored:
  anthropic.key, git.drupalcode.org.key, CLAUDE.local.md,
  .workbench/, scripts/drupalorg.phar
EOF
