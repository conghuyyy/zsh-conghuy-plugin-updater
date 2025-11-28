#
# zsh-conghuy-plugin-updater
# Automatically updates selected Oh-My-Zsh custom plugins
#

# User-defined list of plugin *names* (set in .zshrc)
typeset -ga AUTO_UPDATE_ZSH_CONGHUY_PLUGINS

# Internal resolved list of plugin directories
typeset -ga _CONGHUY_PLUGIN_DIRS=()

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

# Update logic
conghuy_update_plugins() {
  echo "[conghuy-updater] Checking for plugin updates…"

  for dir in "${_CONGHUY_PLUGIN_DIRS[@]}"; do
    (
      cd "$dir" || return

      git fetch origin main >/dev/null 2>&1

      local local_sha remote_sha
      local_sha=$(git rev-parse HEAD 2>/dev/null)
      remote_sha=$(git rev-parse origin/main 2>/dev/null)

      if [[ "$local_sha" != "$remote_sha" ]]; then
        echo "[conghuy-updater] Updating $(basename "$dir")…"
        git pull --ff-only origin main
      else
        echo "[conghuy-updater] $(basename "$dir") is up to date."
      fi
    )
  done
}

# Manual command
alias update_conghuy_plugins="conghuy_update_plugins"

# Optional Y/n auto-update prompt once per session
_conghuy_maybe_auto_update() {
  echo -n "[conghuy-updater] Update zsh plugins? [Y/n] "
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
