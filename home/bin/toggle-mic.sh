#! /bin/sh
# With icon indicating the state of the mic
set -e

count=`amixer set Capture toggle | grep -F '[on]' | wc -l`
if [ $count != "0" ]; then
    state="ON"
    icon="audio-input-microphone-symbolic"
else
    state="OFF"
    icon="audio-input-microphone-muted-symbolic"
fi
notify-send --hint=int:transient:1 -i $icon "Mic is now: $state"