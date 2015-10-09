#!/bin/sh
# Downloads all the dotfiles and copies them to ~
# You can run it with this:
# curl -s https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh | sh

ZIP=master.zip
URL=https://github.com/flesler/dotfiles/archive/$ZIP
TMP=dotfiles-master
EXCLUDE="$TMP/README.md $TMP/install.sh"
BKP_SUF=.bkp #~

# Ensure clean state
rm -rf $TMP
# Download and extract zip
curl $URL -sLOk
unzip -q $ZIP -d . -x $EXCLUDE
rm $ZIP

for file in `cd $TMP && find`; do
	[ "$file" = "." ] && continue

	src=$TMP/$file
	dest=~/$file
	# Create directories if missing on destination
	if [ -d "$src" ]; then
		if [ ! -d "$dest" ]; then
			mkdir -p $dest
			echo "created directory $dest"
		fi
		continue
	fi
	# If conflicted...
	if [ -f "$dest" ]; then
		echo -n "$dest exists. (s)kip, (o)verwrite, (b)ackup?"
		read -sn 1 -p ''
		echo
		case $REPLY in
			s) continue;;
			o) ;;
			b) 
				cp "$dest" "$dest$BKP_SUF"
				echo "backed up $dest to $dest$BKP_SUF";;
			*)
				echo "unknown letter $REPLY, skipping"
				continue;;
		esac
	fi
	
	cp -f "$src" "$dest"
	echo "copied $src to $dest"
done

rm -r $TMP
