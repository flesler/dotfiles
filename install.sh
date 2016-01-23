#!/bin/sh
# Downloads all the dotfiles and copies them to ~
#
# Run it interactively (decide on conflicts):
# sh -i <(curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh)
#
# Remove the -i to automatically override any conflicted file

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

	if [ ! -f "$dest" ]; then
		:
	elif cmp -s "$src" "$dest"; then
		# Same file, auto-skip
		continue
	# If conflicted AND interactive
	elif [ -n "$PS1" ]; then
		echo -n "$dest is a file. (s)kip, (o)verwrite, (b)ackup?"
		read -sn 1 -p ' ' chr
		echo
		case $chr in
			s) continue;;
			o) ;;
			b) 
				mv "$dest" "$dest$BKP"
				echo "backed up to $dest$BKP";;
			*)
				echo "unknown letter '$chr', skipping"
				continue;;
		esac
	fi
	
	echo "copying to $dest"
	cp "$src" "$dest"
	# FIXME: Not really symlinking in Git Bash
	#ln -sf "$src" "$dest"
done

# Create an empty one so the user notices it
touch ~/.bash_extras
