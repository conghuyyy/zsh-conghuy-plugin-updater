#
# zsh-conghuy-plugin-updater
# Automatically updates selected Oh-My-Zsh custom plugins
#

# User-defined list of plugin *names* (set in .zshrc)
typeset -ga AUTO_UPDATE_ZSH_CONGHUY_PLUGINS

# Internal resolved list of plugin directories
typeset -ga _CONGHUY_PLUGIN_DIRS=()
typeset -ga _CONGHUY_PENDING_UPDATES=()

# Colors (only if stdout is a terminal)
if [[ -t 1 ]]; then
  CONGHUY_COLOR_TAG=$'\033[36m'      # cyan
  CONGHUY_COLOR_OK=$'\033[32m'       # green
  CONGHUY_COLOR_YELLOW=$'\033[33m'   # yellow
  CONGHUY_COLOR_ERR=$'\033[31m'      # red
  CONGHUY_COLOR_RESET=$'\033[0m'
else
  CONGHUY_COLOR_TAG=""
  CONGHUY_COLOR_OK=""
  CONGHUY_COLOR_YELLOW=""
  CONGHUY_COLOR_ERR=""
  CONGHUY_COLOR_RESET=""
fi

# Convert plugin names → full paths
_conghuy_resolve_plugin_dirs() {
  _CONGHUY_PLUGIN_DIRS=()  # clear previous

  for plugin in "${AUTO_UPDATE_ZSH_CONGHUY_PLUGINS[@]}"; do
    local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"

    if [[ -d "$dir/.git" ]]; then
      _CONGHUY_PLUGIN_DIRS+=("$dir")
    else
      printf '%b\n' "${CONGHUY_COLOR_YELLOW}[conghuy-updater]${CONGHUY_COLOR_RESET} Plugin not found or missing git repo → $dir"
    fi
  done
}

# Check which plugins have new versions on origin/main
_conghuy_check_updates() {
  _CONGHUY_PENDING_UPDATES=()

  for dir in "${_CONGHUY_PLUGIN_DIRS[@]}"; do
    if [[ ! -d "$dir/.git" ]]; then
      printf '%b\n' "${CONGHUY_COLOR_YELLOW}[conghuy-updater]${CONGHUY_COLOR_RESET} Skipping ${CONGHUY_COLOR_YELLOW}$(basename "$dir")${CONGHUY_COLOR_RESET} (no git repo)"
      continue
    fi

    # Stay in the same shell; save and restore PWD
    local oldpwd=$PWD
    cd "$dir" || continue

    git fetch origin main >/dev/null 2>&1 || {
      printf '%b\n' "${CONGHUY_COLOR_ERR}[conghuy-updater]${CONGHUY_COLOR_RESET} Failed to fetch updates for ${CONGHUY_COLOR_YELLOW}$(basename "$dir")${CONGHUY_COLOR_RESET}"
      cd "$oldpwd"
      continue
    }

    # No SHA vars: just compare HEAD vs origin/main
    if ! git diff --quiet HEAD origin/main 2>/dev/null; then
      printf '%b\n' "${CONGHUY_COLOR_TAG}[conghuy-updater]${CONGHUY_COLOR_RESET} New version available for ${CONGHUY_COLOR_YELLOW}$(basename "$dir")${CONGHUY_COLOR_RESET}."
      _CONGHUY_PENDING_UPDATES+=("$dir")
    else
      printf '%b\n' "${CONGHUY_COLOR_OK}[conghuy-updater]${CONGHUY_COLOR_RESET} ${CONGHUY_COLOR_YELLOW}$(basename "$dir")${CONGHUY_COLOR_RESET} is up to date."
    fi

    cd "$oldpwd"
  done
}

# Apply updates (only to plugins in _CONGHUY_PENDING_UPDATES)
conghuy_update_plugins() {
  if (( ${#_CONGHUY_PENDING_UPDATES[@]} == 0 )); then
    printf '%b\n' "${CONGHUY_COLOR_OK}[conghuy-updater]${CONGHUY_COLOR_RESET} No updates to apply."
    return 0
  fi

  for dir in "${_CONGHUY_PENDING_UPDATES[@]}"; do
    (
      cd "$dir" || return
      printf '%b\n' "${CONGHUY_COLOR_TAG}[conghuy-updater]${CONGHUY_COLOR_RESET} Updating ${CONGHUY_COLOR_YELLOW}$(basename "$dir")${CONGHUY_COLOR_RESET}..."
      git pull --ff-only origin main
    )
  done
}

# Optional Y/n auto-update prompt helper (runs resolve + check + maybe update)
_conghuy_maybe_auto_update() {
  _conghuy_resolve_plugin_dirs
  _conghuy_check_updates

  if (( ${#_CONGHUY_PENDING_UPDATES[@]} == 0 )); then
    # Everything is up to date; silently exit
    return
  fi

  printf '%b' "${CONGHUY_COLOR_TAG}[conghuy-updater]${CONGHUY_COLOR_RESET} Update zsh plugins now? [Y/n] "
  if read -q; then
    printf '\n'
    conghuy_update_plugins
  else
    printf '\n'
    printf '%b\n' "${CONGHUY_COLOR_YELLOW}[conghuy-updater]${CONGHUY_COLOR_RESET} Auto-update skipped for this session."
  fi
}

# Manual command: check + update
alias update_conghuy_plugins='_conghuy_maybe_auto_update'

# Self-update (manual)
_conghuy_updater_self_update() {
  local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-conghuy-plugin-updater"

  if [[ ! -d "$dir/.git" ]]; then
    printf '%b\n' "${CONGHUY_COLOR_ERR}[conghuy-updater]${CONGHUY_COLOR_RESET} Self-update failed: not a git repository."
    return 1
  fi

  (
    cd "$dir" || return
    printf '%b\n' "${CONGHUY_COLOR_TAG}[conghuy-updater]${CONGHUY_COLOR_RESET} Pulling latest version…"

    if git pull --ff-only origin main; then
      printf '%b\n' "${CONGHUY_COLOR_OK}[conghuy-updater]${CONGHUY_COLOR_RESET} Self-update complete."
      printf '%b\n' "${CONGHUY_COLOR_YELLOW}[conghuy-updater]${CONGHUY_COLOR_RESET} Restart your terminal or run: ${CONGHUY_COLOR_TAG}source ~/.zshrc${CONGHUY_COLOR_RESET}"
    else
      printf '%b\n' "${CONGHUY_COLOR_ERR}[conghuy-updater]${CONGHUY_COLOR_RESET} Self-update failed."
    fi
  )
}

alias self_update_conghuy_updater='_conghuy_updater_self_update'
