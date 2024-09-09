## Delete the Mouse Dependency

Personal configurations and dotfiles, managed by [homux](https://github.com/ArielHorwitz/homux), and a suite of utilities and scripts that help me live mostly in the terminal and disconnect the mouse permanently. I use arch, btw.

> I'd just like to interject for a moment. What you’re referring to as my workstation, is in fact, Linux/KMonad, or as I’ve recently taken to calling it, Linux plus KMonad. An operating system is not complete unto itself, but rather the foundation of a mouseless system made possible by KMonad, shell utilities and vital system components comprising an efficient and streamlined workstation operated via the keyboard. Many computer users run a lame system, without realizing it.
>
> Through a peculiar turn of events, the hardcore terminal nerds today use an editor called "*vi/vim/nvim*" and many of its users are not aware that it is not solving the mouse dependency. Many apps are actually GUIs, and these people are using them, while the editor alone is just one part of the system they use.

### How to use this

Really this repository is public more so that others can study it. For posterity however, I will document how I use it. Here are some references to help understand everything that is going on:
* [KMonad](https://github.com/kmonad/kmonad/)
* [spongecrab](https://github.com/ArielHorwitz/spongecrab)
* [homux](https://github.com/ArielHorwitz/homux)
* [ArchWiki](https://wiki.archlinux.org/)

The repository contains everything I need to configure a new arch installation (other than perhaps browser plugins). I should have a new computer set up to be a 1-to-1 clone as my daily driver following these steps more or less (some reboots may be required - some may be skipped if you know how to workaround missing paths):
* Clone repository to `~/.dmd`
* Install packages, tools, and scripts:
    - Run `install-arch` (arch/aur packages)
    - Run `install-bin` (scripts from the [bin](/bin) directory)
    - Run `install-crates` (tools via `cargo install`)
* Install and configure stuff using `install-*` and `configure-*` scripts from the [bin](/bin)
* Copy/generate `~/.config/homux/secrets.toml`
* Run `homux apply` (this essentially configures everything for the user)

If I want to update configs then I would edit `~/.dmd/home` and rerun `homux apply`.
