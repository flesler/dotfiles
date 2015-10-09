# Directories
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cb='cd -'
alias e='explorer .'
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
alias add='git add --all'
alias stash='add && git stash'
alias stashpull='stash && git pull --rebase && git stash pop'
alias stashpush='stash && git push && git stash pop'
alias rebase='git rebase master'
alias steprebase='add && git rebase --continue'
alias rev='git reset --soft HEAD^'

function commit() {
  # Accept all changes, commit and copy commit msg to clipboard
  add && git commit -m "$1" && echo "$1" | clip
}
function tag() {
  git tag "$1" && git push --tags
}
# Shell
alias rc='vi ~/.bashrc && source ~/.bashrc'
alias rr='rm -r'
alias mp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'
# History
function rep() {
  # Re-execute the last command that matches a filter (ignore last line, remove IDs)
  cmd=`history | sed '$d' | tr -s ' ' | cut -d' ' -f3- | grep "$1" | tail -n 1`
  echo "$cmd"
  [ "$2" == "-e" ] && $cmd
}
# Utils
alias online='ping yahoo.com -t'
alias lintall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jshint"
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"

source ~/.bash_profile
source ~/.inputrc # Not really intented like this no?
