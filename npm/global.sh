#!/bin/sh -eu
# Install all the global NPM modules I usually use
# All this could be a one-liner, made it fancier to justify having an sh just for this

MODULES='parallel uver live-server nip jshint htmlhint jscs nodemon node-inspector'

for module in $MODULES; do
	echo "Installing $module..."
	npm install --global ${module}@latest
done