#
# zsh-conghuy-plugin-updater
# Automatically updates selected Oh-My-Zsh custom plugins
#

# User-defined list of plugin *names* (set in .zshrc)
typeset -ga AUTO_UPDATE_ZSH_CONGHUY_PLUGINS

# Internal resolved list of plugin directories
typeset -ga _CONGHUY_PLUGIN_DIRS=()
typeset -ga _CONGHUY_PENDING_UPDATES=()

# Convert plugin names → full paths
_conghuy_resolve_plugin_dirs() {
  _CONGHUY_PLUGIN_DIRS=()  # clear previous

  for plugin in "${AUTO_UPDATE_ZSH_CONGHUY_PLUGINS[@]}"; do
    local dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"

    if [[ -d "$dir/.git" ]]; then
      _CONGHUY_PLUGIN_DIRS+=("$dir")
    else
      echo "[conghuy-updater] Warning: plugin not found or missing git repo → $dir"
    fi
  done
}

# Check which plugins have new versions on origin/main
_conghuy_check_updates() {
  _CONGHUY_PENDING_UPDATES=()

  for dir in "${_CONGHUY_PLUGIN_DIRS[@]}"; do
    if [[ ! -d "$dir/.git" ]]; then
      echo "[conghuy-updater] Skipping $(basename "$dir") (no git repo)"
      continue
    fi

    cd "$dir" || continue

    git fetch origin main >/dev/null 2>&1 || {
      echo "[conghuy-updater] Failed to fetch updates for $(basename "$dir")"
      continue
    }

    local local_sha remote_sha
    local_sha=$(git rev-parse HEAD 2>/dev/null) || continue
    remote_sha=$(git rev-parse origin/main 2>/dev/null) || continue

    if [[ "$local_sha" != "$remote_sha" ]]; then
      echo "[conghuy-updater] New version available for $(basename "$dir")."
      _CONGHUY_PENDING_UPDATES+=("$dir")
    else
      echo "[conghuy-updater] $(basename "$dir") is up to date."
    fi
  done
}

# Apply updates (only to plugins in _CONGHUY_PENDING_UPDATES)
conghuy_update_plugins() {
  if (( ${#_CONGHUY_PENDING_UPDATES[@]} == 0 )); then
    echo "[conghuy-updater] No updates to apply."
    return 0
  fi

  for dir in "${_CONGHUY_PENDING_UPDATES[@]}"; do
    cd "$dir" || continue
    echo "[conghuy-updater] Updating $(basename "$dir")…"
    git pull --ff-only origin main
  done
}

# Manual command: check + update
alias update_conghuy_plugins='_conghuy_check_updates; conghuy_update_plugins'

# Optional Y/n auto-update prompt once per session
_conghuy_maybe_auto_update() {
  # First: check if any plugins have new versions
  _conghuy_check_updates

  # If nothing to update, don't bother asking
  if (( ${#_CONGHUY_PENDING_UPDATES[@]} == 0 )); then
    # Everything is up to date; silently exit
    return
  fi

  echo -n "[conghuy-updater] Update zsh plugins now? [Y/n] "
  if read -q; then
    echo ""
    conghuy_update_plugins
  else
    echo ""
    echo "[conghuy-updater] Auto-update skipped for this session."
  fi
}

# Do initial setup
_conghuy_resolve_plugin_dirs

# Run prompt once per session
if [[ -z "$CONGHUY_AUTO_UPDATE_RAN" ]]; then
  export CONGHUY_AUTO_UPDATE_RAN=1
  _conghuy_maybe_auto_update
fi
