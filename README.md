# dotfiles

## Description

My dotfiles, meant to be used on Windows on a Unix-like environment like [Git Bash](https://git-scm.com/download/win)

## Installation

### One-liner Installation

```bash
curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh | sh
```

### Manual Git

```bash
df=~/dotfiles
mkdir -p $df
git clone git://github.com/flesler/dotfiles.git $df
cd $df
./install.sh
```

### Manual ZIP

Download the files you want or the whole [zip](https://github.com/flesler/dotfiles/archive/master.zip) and place them in your `$HOME`.

