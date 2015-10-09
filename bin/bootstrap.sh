#!/bin/sh
ZIP=master.zip
URL=https://github.com/flesler/dotfiles/archive/$ZIP
TMP=dotfiles-master

# Ensure clean state
rm -rf $TMP && mkdir -p $TMP

# Download and extract zip
curl $URL -sLOk
unzip -q $ZIP -d .
rm $ZIP

for file in `ls -A $TMP`; do
	case $file in
		README.md) ;;
		bin/bootstrap.sh) ;;
		*) 
			# TODO: Move to ~, make backups
			echo $TMP/$file
			;;
	esac
done

rm -r $TMP
