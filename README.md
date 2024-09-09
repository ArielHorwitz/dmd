# Delete the Mouse Dependency

Personal configurations and dotfiles, managed by [homux](https://github.com/ArielHorwitz/homux), and a suite of utilities and scripts that help me live mostly in the terminal and disconnect the mouse permanently. I use arch, btw.

> I'd just like to interject for a moment. What you’re referring to as my workstation, is in fact, Linux/KMonad, or as I’ve recently taken to calling it, Linux plus KMonad. An operating system is not complete unto itself, but rather the foundation of a mouseless system made possible by KMonad, shell utilities and vital system components comprising an efficient and streamlined workstation operated via the keyboard. Many computer users run a lame system, without realizing it.
>
> Through a peculiar turn of events, the hardcore terminal nerds today use an editor called "*vi/vim/nvim*" and many of its users are not aware that it is not solving the mouse dependency. Many apps are actually GUIs, and these people are using them, while the editor alone is just one part of the system they use.

## How to use this

I don't expect anyone to use this repository as-is, seeing as it uses many custom-built tools and some very particular personalizations. That being said, here are some references to help understand what is going on:
* [KMonad](https://github.com/kmonad/kmonad/) - for making the keyboard 10x more useful
* [spongecrab](https://github.com/ArielHorwitz/spongecrab) - for making bash scripts 10x more useful
* [homux](https://github.com/ArielHorwitz/homux) (and by extension, [matchpick](https://github.com/ArielHorwitz/matchpick)) - for managing dotfiles even across hosts
* [ArchWiki](https://wiki.archlinux.org/) - I mean it's so good for Linux in general

### Fresh installation
The repository contains everything I need to configure a new arch installation (other than perhaps browser plugins). I should have a new computer set up to be a 1-to-1 clone of my daily driver following these steps more or less (some reboots may be required - some may be skipped if you know how to workaround missing paths):
* Clone repository to `~/.dmd`
* Install packages, tools, and scripts:
    - Run `install-arch` ([arch/aur packages](/dependencies/aur.txt))
    - Run `install-bin` (custom scripts from the [bin](/bin) directory)
    - Run `install-crates` ([tools](/dependencies/cargo.txt) via `cargo install`)
* Install and configure stuff using `install-*` and `configure-*` scripts from the [bin](/bin) directory
* Apply the dotfiles
    - Create temporary config at `~/.config/homux/config.toml` with `source = ".dmd/home/"`
    - Copy/generate `~/.config/homux/secrets.toml`
    - Run `homux apply`

### Updating configuration
If I want to update/change configs then I would simply edit `~/.dmd/home` and rerun `homux apply` (and mostly likely also `git push`).
