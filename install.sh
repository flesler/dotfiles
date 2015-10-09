#!/bin/sh
# Downloads all the dotfiles and copies them to ~
# You can run it with this:
# curl --silent https://raw.githubusercontent.com/flesler/dotfiles/master/install.sh | sh

ZIP=master.zip
URL=https://github.com/flesler/dotfiles/archive/$ZIP
TMP=dotfiles-master
EXCLUDE="$TMP/README.md $TMP/install.sh"

# Ensure clean state
rm -rf $TMP
# Download and extract zip
curl $URL -sLOk
unzip -q $ZIP -d . -x $EXCLUDE
rm $ZIP

for file in `ls -A $TMP`; do
	# TODO: Move to ~, make backups
	echo $TMP/$file
done

rm -r $TMP
