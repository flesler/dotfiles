alias rc='vi ~/.bashrc && . ~/.bashrc'
# Directories
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'i
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
alias stashpull='git stash && git pull --rebase && git stash pop'
alias stashpush='git stash && git push && git stash pop'
alias rebase='git rebase master'
alias steprebase='add && git rebase --continue'
alias rev='git reset --soft HEAD^'
alias revert='git reset --hard HEAD'

function commit() {
	# Accept all changes, commit and copy commit msg to clipboard
  add && git commit -m "$1" && echo "$1" | clip
}
# Software
alias subl='/c/Programas/Sublime3/subl -a'
alias e='explorer .'
# Utils
alias online='ping yahoo.com -t'
alias lintall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jshint"
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"
# Various tweaks
shopt -s cdspell # correct dir spelling errors on cd
shopt -s no_empty_cmd_completion # don't try to complete empty cmds
unset HISTFILE
HISTCONTROL=ignoredups