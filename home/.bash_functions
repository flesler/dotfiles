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

# Opens a path or the current directory using the default opener
# USAGE:
#	$ e
#	$ e ~/etc
function e() {
	#if [ -z "$1" ] ; then
	#	explorer .
	#else
	#	explorer $(winpath "$1")
	#fi
	# Linux version
	xdg-open "${1:-.}"
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

# For Linux
function clip() {
	# Copy alias, copy to both clipboards
	if [ "$#" == 0 ]; then
		xclip
		xclip -o | xclip -sel clip
	else
		xclip $*
	fi
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

# Alias for --help | less
# USAGE:
#	$ h grep
function h() {
	$@ --help | less
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
	git add -A && git commit -m "$@" && echo "$1" | clip
}

# Stashes unstaged files, commits and restores the files
function cms() {
  git stash save --keep-index && cm "$@" ; git stash pop
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

# Node/NPM

function n() {
	pref=$1
	# Just n to see the current version
	if [ "$pref" == "" ]; then
		node --version
		return
	fi

	# Can provide just the major or major.minor version
	ver=$(nvm list | grep -Eo "$pref\.[0-9.]+")
	if [ "$ver" == "" ]; then
		1>2 echo "No Node.js version found starting with $pref"
	else
		nvm use $ver
	fi
}

function nr() {
	if [ ! -f "package.json" ]; then
		1>2 echo "No package.json in this directory"
		return
	fi

	node_ver=$(grep '"node"' package.json | sed -E 's/.+"([0-9.]+)\..+/\1/')
	# If current node version doesn't match the requirement, switch
	node -v | grep -q ${node_ver}. || n $node_ver
	npm run -s ${*:-start}
}

# Returns the version of a dependency even if nested
function npmv() {
	find . -path "*/$1/package.json" | xargs grep -H version | sed -E 's/package.json|"version": "|",//g'
}

# Sends a notification after a long running job finishes
function remind(){
    start=$(date +%s)
    "$@"
    notify-send "$ $(echo $@)" "\nTook $(($(date +%s) - start))s to finish"
}

# Remove entries matching $1 from the bash history, also remove duplicates
function forget() {
  if [ "$1" != "" ]; then
    file=~/.bash_history
    before=$(cat $file | wc -l)
    tac $file | sed -n "/$1/!p" | awk '! seen[$0]++' | tac > t && mv t $file
    #cat $file | sed -n "/$1/!p" | awk '!a[$0]++' | tac > t && mv t $file
    history -c
    history -r
    after=$(cat $file | wc -l)
    echo "Trimmed $file, lines: $before -> $after"
  fi
}

# Use Node as a calculator
function calc() {
	node -pe "with(Math) { $* }"
}

function sd() {
  line="sudo $(tail -n1 ~/.bash_history)"
  echo $line
  $line
}