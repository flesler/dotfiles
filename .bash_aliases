# Directories

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cb='cd -'

# Node.js

alias n='node server'
alias prod='NODE_ENV=production'
alias ni='node-debug --save-live-edit true -p 9090 -c '
alias r='npm run'
alias ts='node -e "console.log(new Date(+process.argv[1]).toISOString())" -- '

# Git

alias st='git status'
alias d='git diff'
alias p='git push'
alias pf='p -f'
alias add='git add --all'
alias stash='add && git stash'
alias stashpull='stash && git pull --rebase && git stash pop'
alias stashpush='stash && git push && git stash pop'
alias rebase='git rebase master'
alias steprebase='add && git rebase --continue'
alias rev='git reset --soft HEAD^'

# Shell

alias rr='rm -r'
alias mp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'

# Utils

alias online='ping yahoo.com -t'
alias lintall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jshint"
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"
