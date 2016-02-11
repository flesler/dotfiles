# Shell

# Create a directory and cd to it
function mkc() {
	mkdir -p "$@" && cd "$@"
}

# Converts one or more Unix paths to absolute Windows form
function winpath() {
	for path; do
		if [ -d "$path" ]; then
			path=`cd "$path" && pwd -W`
		else
			path="$(pwd -W)/$path"
		fi
		echo "$path" | sed 's|/|\\|g'
	done
}

# Opens a path or the current directory using Windows Explorer
# USAGE:
#	$ e
#	$ e ~/etc
function e() {
	if [ -z "$1" ] ; then
		explorer .
	else
		explorer $(winpath "$1")
	fi
}

# Pipes stdin into an editor (defaults to $EDITOR or vi)
# USAGE:
#	$ echo "something" | viewstdin
#	$ echo "something" | viewstdin subl
function viewstdin() {
	cmd=${*:-${EDITOR:-vi}}
	tmp=/tmp/${RANDOM}${RANDOM}

	cat >$tmp && $cmd $tmp && rm $tmp
}

# Take all arguments as a command, execute it and copy to clipboard
# If no argument is provided, copy last command executed to clipboard
# Uses head -c-1 to remove the new line that is always at the end
# USAGE:
#	$ c echo 1 2 # "1 2" copied
#	$ c          # "echo 1 2" copied
function c() {
	if [ $# == 0 ]; then
		history | tail -n2 | head -n1 | sed 's/^[0-9 ]*//' | head -c-1 | clip
	else
		sh -c "$*" | head -c-1 | clip
	fi
}

# Kills all processes that match a filter on ps -s
# USAGE:
#	$ kl "/node"
function kl() {
	ps -s |\
		grep $1 |\
		sed -r 's/ *([0-9]+) .*/\1/' |\
		while read pid
			do kill -9 $pid
		done
}

# Config

# Edits one of the dotfiles and then re-sources it
# USAGE:
#	$ rc         # edit .bashrc
#	$ rc aliases # edit .bash_aliases
#	$ rc input   # edit .inputrc
function rc() {
	name=${1:-bash}
	editor=${EDITOR:-vi}
	for file in "$name" ".$name" ".${name}rc" ".bash_$name"; do
		path="$HOME/$file"
		if [ -f "$path" ]; then
			echo "editing $file"
			$editor "$path" && . "$path"
			return
		fi
	done

	echo "no file found with that name"
}

# Git

# Commits all files with the provided message and copies it to clipboard
function cm() {
	git add -A && git commit -m "$*" && echo "$*" | clip
}

# IO

# Copies all arguments to the pendrive as a single gzipped tar
# Did a benchmark, copied 2k small files:
# - cp -r : 230 seconds 
# - tar   : 4 seconds 
# - tar.gz: 1 second
#
# USAGE:
#	$ pendrive dir1 dir2 file*
#	$ pendrive -z dir1 dir2 file*
#	$ pendrive g: -z dir1 dir2 file*
function pendrive() {
	if [ "${1:1:1}" = : ]; then
		drive=/${1:0:1}
		shift
	else
		# Guess pendrive drive. Might not always work, get highest drive letter
		drive=$(mount | grep ": " | sort | tail -n1 | cut -d' ' -f3)
	fi

	tarOpts=
	if [ "${1:0:1}" = "-" ]; then
		tarOpts=$1
		shift
	fi

	if [ $# -eq 1 ]; then
		file=$(basename "$1")
	else
		file=$(dirname "$1")
		if [ "$file" = "." ]; then
			file=$(basename "$PWD")
		fi
	fi

	dest=$drive/$file.tar
	if [[ "$tarOpts" = -*z* ]]; then
		dest=$dest.gz
	fi

	echo "Packing all to $dest..."
	start=$SECONDS
	GZIP=-9 tar $tarOpts -cf $dest $@
	echo "Took $(( $SECONDS - $start )) second(s)"
}
