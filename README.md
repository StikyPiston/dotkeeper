# dotkeeper

![A preview of Dotkeeper applying a keep](assets/preview.png)

A *keeper* for your *dotfiles*. See what I did there? *(booooooo)*

To get started, create a folder in `~/.dotkeep` with the name of your **keep**. A **keep** is a place where dots are kept.

## Info

To learn how to use Dotkeeper, see the [wiki](https://github.com/StikyPiston/dotkeeper/wiki)

## Installation

### Method 1: Homebrew

To install with `brew`, simply run:

```bash
brew install stikypiston/formulae/dotkeeper
```

### Method 2: Manual Install

#### Dependencies

To build *dotkeeper*, you will need a working installation of **go**.

You can either:

1. Install go with your package manager of choice (e.g. `brew`)
2. Use the **Nix Devshell** to build the project. (just run `nix develop`)

#### Building

To build, simply run:

```bash
go build
```

Move the resulting `dotkeeper` binary to some place like `/usr/local/bin` or `~/.local/bin`
