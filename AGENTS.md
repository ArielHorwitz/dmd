# AGENTS.md

See [README.md](README.md) for a high-level overview of the repo structure, philosophy, and key tools.

Code style and development directives are in `home/.config/AGENTS.md` — do not duplicate them here.

## Editing workflow

**Always edit source files in this repo, never in `~` or system paths directly.**

Never run `install.sh`, `homux apply`, or `reload-config` — the user will apply changes themselves.

## homux and matchpick

[homux](https://github.com/ArielHorwitz/homux) copies `home/` to `~` with two key features:

- **matchpick patterns** — Conditional blocks in config files delimited by `~>>>` and `~<<<` markers. Blocks are included or excluded based on selections (typically the hostname). This lets a single config file work across multiple machines. Lines containing `#NOMATCHPICK#` are never processed.
- **Variable substitution** — Variables defined in `home/.config/homux/config.toml` under `[variables]` are replaced in config files during apply. Lines containing `#NOHOMUXVARIABLE#` skip variable substitution.

The hostname is automatically added as a selection, so machine-specific config blocks use the hostname as their selector.

## bin/ scripts

- File extensions are stripped during installation (e.g. `foo.sh` becomes `foo`).
- Most shell scripts use [spongecrab](https://github.com/ArielHorwitz/spongecrab) for argument parsing. Look for the `CLI=(...)` array pattern followed by `eval "$(spongecrab ...)"`.
- Scripts are invoked by KMonad, crowfish menus, or directly from the terminal. There is no strict mapping between KMonad layers and scripts.
- Notifications use `notify-send` with dmd icons from `/usr/share/icons/dmd/`.
- Several internal tools (crowfish, spacemux, wlayout, daudio) are scripts in `bin/`, not external dependencies. They follow the same conventions as other scripts in this directory.

## KMonad keyboard layers

KMonad config lives in `home/.config/kmd/kbd/`. The base layer (`0base.kbd`) dispatches to modal layers when home-row keys are held. Text input layers (`text.kbd`) are toggle-based instead of hold. Each `.kbd` file defines one layer or a closely related group.

`kmdrun` launches KMonad with device config from `home/.config/kmd/devices`. `setlayer` tracks the active layer for display in waybar.
