#/bin/bash
# Disable the laptop's keyboard since it's leaking keystrokes (F12)
# @see https://hirazone.medium.com/how-to-disable-laptop-keyboard-on-ubuntu-59f7b7b81727

# $ xinput --list
# ~/bin/disable-keyboard.sh --enable
disable=--disable
option=${1:-$disable}
# keyboard='20 21 23'
# keyboard='14 15 17'
keyboard='19 21 22'
keyboard_text='Mechanical Gaming Keyboard'

if [ "$option" == "$disable" ] && ! xinput --list | grep "$keyboard_text" >/dev/null; then
  echo "WARNING: No $keyboard_text detected, enabling"
  option=--enable
fi

xinput --list | while read line; do
  echo '>>>' $line
    # xinput $option $code
done

xinput --list

# ↳ Dell WMI hotkeys                        	id=18	[slave  keyboard (3)]
#     ↳ AT Translated Set 2 keyboard            	id=19	[slave  keyboard (3)]
#     ↳ DELL Wireless hotkeys                   	id=21	[slave  keyboard (3)]

