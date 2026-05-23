# Delete the Mouse Dependency

A complete workstation provisioning and configuration system for a fully keyboard-driven Arch Linux setup. This repo contains everything needed to go from a bare Arch installation to a fully configured, mouseless workstation — system packages, keyboard remapping, window management, utility scripts, fonts, icons, and all user configuration.

I use arch, btw.

> I'd just like to interject for a moment. What you're referring to as my workstation, is in fact, Linux/KMonad, or as I've recently taken to calling it, Linux plus KMonad. An operating system is not complete unto itself, but rather the foundation of a mouseless system made possible by KMonad, shell utilities and vital system components comprising an efficient and streamlined workstation operated via the keyboard. Many computer users run a lame system, without realizing it.
>
> Through a peculiar turn of events, the hardcore terminal nerds today use an editor called "*vi/vim/nvim*" and many of its users are not aware that it is not solving the mouse dependency. Many apps are actually GUIs, and these people are using them, while the editor alone is just one part of the system they use.

## Philosophy

The core idea is that the keyboard should control everything — not just text editing, but window management, audio, workspaces, application launching, and system administration. [KMonad](https://github.com/kmonad/kmonad/) makes this possible by remapping the keyboard into modal layers (inspired by vim), where holding a home-row key transforms the entire keyboard into a control surface for a specific subsystem.

[Hyprland](https://hyprland.org/) serves as the Wayland compositor, but its keybinding config is kept minimal — mostly failsafe bindings to recover if KMonad isn't running. The real input system lives in KMonad.

## What this repo manages

This is more than dotfiles. The installer provisions an entire workstation:

| Component | What it does | Location |
|-----------|-------------|----------|
| **System packages** | AUR packages via paru/yay | `setup/aur.txt` |
| **Rust crates** | CLI tools installed via cargo | `setup/crates.txt` |
| **Utility scripts** | Shell and Python scripts installed to system PATH | `bin/` |
| **System configuration** | sudoers, udev rules, network, systemd timers, PATH setup | `setup/` |
| **User configuration** | All dotfiles and app config, applied via homux | `home/` |
| **Fonts** | Nerd Fonts, Mononoki, Ubuntu, Noto Color Emoji | downloaded by installer |
| **Icons** | Notification and status bar icons | `icons/` |

## Directory structure

```
~/.dmd/
├── bin/           Utility scripts (installed to system PATH)
├── home/          Source of truth for all user config (applied via homux)
│   ├── .config/   App and tool configuration
│   └── ...
├── setup/         System provisioning files (package lists, config templates, permissions)
├── icons/         Notification and status bar icons
└── install.sh     Component-based installer
```

## The input system

KMonad remaps the keyboard into modal layers. The **base layer** is a dispatcher — most home-row keys activate another layer when held, turning the keyboard into a control surface for that subsystem (audio, window management, mouse emulation, application launching, etc.). Two layers are **toggle-based** for text input (English and Hebrew), since you need to type freely without holding a key. Each text input layer has a key to return to the base layer.

KMonad layers are defined in `home/.config/kmd/kbd/`. KMonad keys can trigger arbitrary commands, and many of the scripts in `bin/` exist to make these invocations convenient.

## Key tools

External dependencies are installed by `install.sh`. Internal tools are scripts in `bin/`, maintained as part of this repo.

### [homux](https://github.com/ArielHorwitz/homux)
Dotfile manager that copies `home/` to `~` with support for **variable substitution**. This enables a single set of config files that adapt to different machines.

### [matchpick](https://github.com/ArielHorwitz/matchpick)
Conditional block processor used by homux. Blocks in config files delimited by `~>>>` and `~<<<` markers are included or excluded based on selections (typically the hostname), enabling machine-specific config within shared files.

### [KMonad](https://github.com/kmonad/kmonad/)
Keyboard remapping daemon. The foundation of the entire input system. Layers are defined in `home/.config/kmd/kbd/`, and `kmdrun` manages launching it with the right device config.

### [spongecrab](https://github.com/ArielHorwitz/spongecrab)
Argument parser for bash scripts. A keystone dependency — most shell scripts in `bin/` use spongecrab to define their CLI interface and will not function without it.

### crowfish
Hierarchical menu system with TOML-defined menus (internal). Entries can execute commands or dispatch to sub-menus. This is the primary way to access the full range of available commands without memorizing them or rummaging through the terminal. Menus are defined in `home/.config/crowfish/`.

### Other tools

- **spacemux** — Workspace grid manager for Hyprland (internal). Config: `home/.config/spacemux/`.
- **wlayout** — Window layout presets (internal). Spawns commands and arranges their windows into predefined positions. Config: `home/.config/wlayout/`.
- **daudio** — Audio device and volume management with notification feedback (internal).

## Fresh installation

The repository contains everything needed to configure a new Arch installation. A new machine should be a clone of the daily driver after these steps (a reboot may be required):

1. Clone repository to `~/.dmd`
2. Install using: `~/.dmd/install.sh all`
3. Copy or generate the `~/.config/homux/secrets.toml` file
4. Apply the dotfiles: `homux apply` (first run needs `--config-file ~/.dmd/home/.config/homux/config.toml`)

`install.sh` is idempotent — it must be safe to run any component at any time, repeatedly. This is a cornerstone of how dmd works.

Run `install.sh --help` for component-by-component usage.

## Making changes

This repo is continuously evolving — changes touch config files, scripts, package lists, and more. The workflow depends on what changed:

- **Config files** (`home/`): run `install.sh home` (or `homux apply` directly)
- **Scripts** (`bin/`): run `install.sh scripts`
- **Config + scripts together**: run `install.sh h s` (the most common case in practice)
- **Packages or crates** (`setup/`): run `install.sh packages` or `install.sh crates`
- **Any combination**: `install.sh` accepts multiple components in one invocation

After applying config changes, run `reload-config` if the change affects a running service (Hyprland, waybar, dunst, etc.).

Always edit source files in this repo, never in `~` or system paths directly. Commit and push.

## References

* [KMonad](https://github.com/kmonad/kmonad/) - keyboard remapping with layers
* [Hyprland](https://hyprland.org/) - Wayland compositor
* [spongecrab](https://github.com/ArielHorwitz/spongecrab) - bash argument parsing
* [homux](https://github.com/ArielHorwitz/homux) - dotfile management
* [matchpick](https://github.com/ArielHorwitz/matchpick) - conditional blocks in config files
* [ArchWiki](https://wiki.archlinux.org/) - I mean it's so good for Linux in general
