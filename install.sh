#!/bin/sh -i
# Downloads all the dotfiles and copies them to ~
# You can run it with this:
# curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh | sh

# FIXME: `read` doesn't work when used non-interactive

DF=~/.dotfiles
BKP=.bkp #~

if [ -d $DF ]; then
	cd $DF
	git pull --rebase
else
	git clone https://github.com/flesler/dotfiles.git $DF
	cd $DF
fi

for src in $(find home ! -name home); do
	dest=${src/home/~}
	# Create directories if missing on destination
	if [ -d "$src" ]; then
		mkdir -p "$dest"
		continue
	fi
	# If conflicted..., override if it's a symlink
	if [ -f "$dest" ]; then
		echo -n "$dest is a file. (s)kip, (o)verwrite, (b)ackup?"
		read -sn 1 -p ' ' chr
		echo
		case $chr in
			s) continue;;
			o) ;;
			b) 
				mv "$dest" "$dest$BKP"
				echo "backed up $dest to $dest$BKP";;
			*)
				echo "unknown letter '$chr', skipping"
				continue;;
		esac
	fi
	
	# FIXME: Not really symlinking in Git Bash
	ln -sf "$src" "$dest"
	echo "symlinked $src to $dest"
done

# Create an empty one so the user notices it
touch ~/.bash_extras