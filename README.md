# Configuration

1. Add your plugin names in .zshrc (before source $ZSH/oh-my-zsh.sh):

```sh
    AUTO_UPDATE_ZSH_CONGHUY_PLUGINS=(
      zsh-conghuy-dev-utilities
      ...
    )
```

2. Enable the updater plugin:

```sh
    plugins=(
    # other plugins...
    zsh-conghuy-plugin-updater
)
```

## Manual update:

* For itself:
```sh
    self_update_conghuy_updater
```

* For other plugins:
```sh
    update_conghuy_plugins
```



## Requirements:

* Managed plugins must be in:
~/.oh-my-zsh/custom/plugins/<name>

* Must be Git repos using branch main

<hr />

# Installation

## Oh My Zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/custom/plugins`)

    ```sh
    git clone https://github.com/conghuyyy/zsh-conghuy-plugin-updater.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-conghuy-plugin-updater
    ```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

    ```sh
    plugins=( 
        # other plugins...
        zsh-conghuy-plugin-updater
    )
    ```

3. Start a new terminal session.

## Manual (Git Clone)

1. Clone this repository somewhere on your machine. This guide will assume `~/.zsh/zsh-conghuy-plugin-updater`.

    ```sh
    git clone https://github.com/conghuyyy/zsh-conghuy-plugin-updater.git ~/.zsh/zsh-conghuy-plugin-updater
    ```

2. Add the following to your `.zshrc`:

    ```sh
    source ~/.zsh/zsh-conghuy-plugin-updater
    ```

3. Start a new terminal session.