#!/bin/sh -eu
# Install all the global NPM modules I usually use
# All this could be a one-liner, made it fancier to justify having an sh just for this

MODULES='parallel uver live-server nip jshint htmlhint nodemon'
# Problematic or rarely used
MANUAL='node-inspector jscs node-pv'

# TODO: Look for a static server that supports:
# - LiveReload
# - Jade and Stylus support
# - Static files can be deployed to a static asset host
# - Ideally supports config file on $HOME

for module in $MODULES; do
	echo "Installing $module..."
	npm install --global ${module}@latest
done