# Shell

# Create a directory and cd to it
function mkc() {
	mp "$@" && cd "$@"
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

# Config

# Edits one of the dotfiles and then re-sources it
# USAGE:
#	$ rc # edit .bashrc
#	$ rc aliases # edit .bash_aliases
#	$ rc input # edit .inputrc
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
function commit() {
	git add -A && git commit -m "$1" && echo "$1" | clip
}