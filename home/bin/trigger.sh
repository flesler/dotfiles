#!/bin/bash

# Example: ~/bin/trigger.sh -v -w Mozilla F6 ctrl+a p i z z a Return
# Example: ~/bin/trigger.sh -v -p 100,200 click -r 10 -d 300
# Example: ~/bin/trigger.sh -v wdown -r 30 -d 300

opt=--clearmodifiers
delay=
pos=
dryrun=
verbose=
keys=
cmd=click

while [ $# -gt 0 ]; do
	case $1 in
		-w) opt="$opt --window $(xdotool search --onlyvisible -name $2 | head -1)"; shift ;;
		-r) opt="$opt --repeat $2"; shift ;;
		-d) delay=$2; shift ;;
		-p) pos=${2/[,x]/ } ; shift ;;
		-D) dryrun=1 ;;
		-v) verbose=1 ;;
		# Use these names for mouse buttons
		click) keys=1 ;;
		wheel) keys=2 ;;
		rclick) keys=3 ;;
		wup) keys=4 ;;
		wdown) keys=5 ;;
		# Don't use the numbers for mouse clicks
		# [1-5]) keys="$keys $1" ;;
		*) cmd=key; keys="$keys $1" ;;
	esac
	shift
done

run() {
	if [ "$verbose$dryrun" ]; then
		echo $@
	fi
	if [ ! "$dryrun" ]; then
		$@
	fi
}

if [ "$pos" ]; then
	run xdotool mousemove $pos
fi

if [ "$delay" ]; then
	if [ $cmd == key ]; then
		# for keys apply the delay to the whole series
		opt="$opt --repeat-delay $delay"
	else
		opt="$opt --delay $delay"
	fi
fi

run xdotool $cmd $opt $keys