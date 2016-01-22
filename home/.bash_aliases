# Shell

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -='cd -'
alias ~='cd ~'
alias rr='rm -r'
alias rrf='rr -f'
alias mp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'

# Node.js

alias ns='node server'
alias na='node app'
alias prod='NODE_ENV=production'
alias r='npm run'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "new Date(+(process.argv[1]+'000').slice(0,13)).toISOString()" -- '
alias lintall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jshint"
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"

# Git

# Bring these aliases from .gitconfig to global scope
for k in s d undo rev discard p pf pr st stpll rbc rbm lg; do
	alias $k="git $k"
done

# Internet

alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
alias online='ping yahoo.com -t'
