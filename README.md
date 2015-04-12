# Javier's dotfiles

I want to feel like `~` no matter what so here is my personal collection of settings.

## Installation

You can clone this repository, init the submodules and run the script. Almost all the configuration will be symlinked to your home, backing up the originals founded in there.

```bash
$ git clone git@github.com:javivelasco/dotfiles.git & cd dotfiles
$ git submodule update --init --recursive
```

The installation is made from a `Rakefile` and you can run just the parts that you want. To check what is available:

```bash
$ rake -T
rake configure          # Run all configuration tasks
rake configure:git      # Configure git related dotfiles
rake configure:osx      # Configure OSX (run once)
rake configure:tmux     # Configure TMUX
rake configure:vim      # Configure Vim with Vundler and plugins
rake configure:zsh      # Configure ZSH and bootstrap aliases, functions, etc
rake install            # Run all install tasks
rake install:binaries   # Copy binaries to home folder
rake install:homebrew   # Install homebrew and useful packages
rake install:oh_my_zsh  # Install oh my zsh, pure prompt and syntax highlighter
rake setup              # Run everything
```

So if you want to setup everything just run:

```bash
$ rake setup
```

Or, if you want to run just the zsh configuration for example you can do:

```bash
$ rake configure:zsh
```

All the changes will try to backup a copy of your original configuration but in some cases it's not possible (ie the osx configuration). Be aware of it.

## Notes

- I prefer `zsh` over `bash` so if you configure it your prompt will change.
- If you install *oh my zsh* you'll also get the neat prompt [Pure](https://github.com/sindresorhus/pure) by Sindre Sorhus.
- I encourage you to change the config files to your needs, specially the `osx.sh` script, which is grabbed from awesome [Mathias Bynens dotfiles])(https://github.com/mathiasbynens/dotfiles).
- The OSX script will install in your iTerm2 the theme [Solarized][http://ethanschoonover.com/solarized] and the font Monaco, but you will have to select them from the settings. Also it will link your sublime to a `subl` command.
- If you install Brew you'll get a bunch of useful packages which can take a while.

## Attributions

I've tried to take the best from every dotfiles I've found but I get inspired (and grab some code) from [Ryan Bates](https://github.com/ryanb/dotfiles), [Mathias Bynens](https://github.com/mathiasbynens/dotfiles), [Zach Holman](https://github.com/holman/dotfiles) and [YADR](https://github.com/skwp/dotfiles). Thanks to all of them.

## License

Copyright (c) 2015 - Javier Velasco

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.
