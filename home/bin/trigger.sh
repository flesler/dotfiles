#!/bin/bash

opt=--clearmodifiers
win=
delay=
pos=
dryrun=
verbose=
keys=
cmd=click

while [ $# -gt 0 ]; do
	case $1 in
		-r) opt="$opt --repeat $2"; shift ;;
		-w) win="$2"; shift ;;
		-d) delay=$2; shift ;;
		-p) pos=${2/[,x]/ } ; shift ;;
		-D) dryrun=1 ;;
		-v) verbose=1 ;;
		# Use these names for mouse buttons
		click ) keys=1 ;;
		wheel ) keys=2 ;;
		rclick) keys=3 ;;
		wup   ) keys=4 ;;
		wdown ) keys=5 ;;
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

if [ "$win" ]; then
	run xdotool search --name "$win" windowactivate --sync
fi

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