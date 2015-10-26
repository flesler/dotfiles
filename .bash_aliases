# Shell

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cb='cd -'
alias rr='rm -r'
alias mp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'

# Node.js

alias n='node server'
alias prod='NODE_ENV=production'
alias ni='node-debug --save-live-edit true -p 9090 -c '
alias r='npm run'
alias ts='node -e "console.log(new Date(+process.argv[1]).toISOString())" -- '
alias lintall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jshint"
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"

# Git

alias s='git status'
alias d='git diff'
alias undo='git reset --soft HEAD^'
#alias rev='git reset --hard HEAD^'# Off until i get used to `undo`
alias add='git add -A'
alias p='git push'
alias pf='p -f'
alias pr='git pull --rebase'
alias stash='add && git stash'
alias stashpull='stash && pr && git stash pop'
alias stashpush='stash && p && git stash pop'
alias rebase='git rebase master'
alias rebasec='add && git rebase --continue'
alias rebasea='add && git rebase --abort'

# Internet

alias localip='ipconfig | grep IPv4 | tr " " "\n" | tail -n1'
alias online='ping yahoo.com -t'
