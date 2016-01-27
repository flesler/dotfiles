# dotfiles

## Description

My dotfiles, meant to be used on Windows on a Unix-like environment like [Git Bash](https://git-scm.com/download/win)

## Installation

### One-liner

```bash
# Will ask for a choice for each conflicting file
sh -i <(curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh)
```

```bash
# No confirmation, existing files are automatically overwritten
sh <(curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh)
```

### Manually via Git

```bash
df=~/dotfiles
git clone git://github.com/flesler/dotfiles.git $df
sh -i $df/install.sh
```

### Manually via ZIP

Download the files you want or the whole [zip](https://github.com/flesler/dotfiles/archive/master.zip) and place them in your `$HOME`.

