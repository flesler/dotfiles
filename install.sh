#!/bin/sh
# Downloads all the dotfiles and copies them to ~
# You can run it with this:
# curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh | sh

DF=~/.dotfiles
BKP=.bkp #~

set -ieu

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

	# If conflicted
	if [ -f "$dest" ]; then

		# Same file, auto-skip
		cmp -s "$src" "$dest" && continue

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
	else
		echo "copying to $dest"
	fi
	
	cp "$src" "$dest"
	# FIXME: Not really symlinking in Git Bash
	#ln -sf "$src" "$dest"
done

# Create an empty one so the user notices it
touch ~/.bash_extras