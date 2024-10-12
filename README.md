# Delete the Mouse Dependency

Personal configurations and dotfiles, managed by [homux](https://github.com/ArielHorwitz/homux), and a suite of utilities and scripts that help me live mostly in the terminal and disconnect the mouse permanently. I use arch, btw.

> I'd just like to interject for a moment. What you’re referring to as my workstation, is in fact, Linux/KMonad, or as I’ve recently taken to calling it, Linux plus KMonad. An operating system is not complete unto itself, but rather the foundation of a mouseless system made possible by KMonad, shell utilities and vital system components comprising an efficient and streamlined workstation operated via the keyboard. Many computer users run a lame system, without realizing it.
>
> Through a peculiar turn of events, the hardcore terminal nerds today use an editor called "*vi/vim/nvim*" and many of its users are not aware that it is not solving the mouse dependency. Many apps are actually GUIs, and these people are using them, while the editor alone is just one part of the system they use.

## How to use this

I don't expect anyone to use this repository as-is, seeing as it is a collection of bespoke tools and very particular personalizations. That being said, here are some references to help understand what is going on:
* [KMonad](https://github.com/kmonad/kmonad/) - for making the keyboard 10x more useful
* [spongecrab](https://github.com/ArielHorwitz/spongecrab) - for making bash scripts 10x more useful
* [homux](https://github.com/ArielHorwitz/homux) (and by extension, [matchpick](https://github.com/ArielHorwitz/matchpick)) - for managing dotfiles from a single source across hosts
* [ArchWiki](https://wiki.archlinux.org/) - I mean it's so good for Linux in general

### Fresh installation
The repository contains everything I need to configure a new arch installation (other than perhaps browser plugins). I should have a new computer set up to be a 1-to-1 clone of my daily driver following these steps more or less (a reboot may be required):
* Clone repository to `~/.dmd`
* Install using: `install --all`
* Copy or generate the `~/.config/homux/secrets.toml` file
* Apply the dotfiles: `homux apply` (first run probably needs `--config-file ~/.dmd/home/.config/homux/config.toml`)

### Updating configuration
If I want to add/modify configuration then I would simply edit `~/.dmd/home` and rerun `homux apply` (mostly likely also `git push`).
