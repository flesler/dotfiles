# Shell

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias b='cd -'
alias ~='cd ~'
alias rr='rm -r'
alias rrf='rr -f'
alias mp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'
# Base directory not specified so it's PWD by default but one can pass dirs or files as args after the word
alias ff="grep -A1 -nrFH --exclude-dir={.git,node_modules} --include=*.{js,jade,css,styl,sql,sh,json} -e"

# Node.js

alias ns='node server'
alias na='node app'
alias prod='NODE_ENV=production'
alias r='npm run -s'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "new Date(+(process.argv[1]+'\''000'\'').slice(0,13)).toISOString()" -- '
# This is hacky, but nor --exclude node_modules or --exclude-path ~/.jshintignore work as expected
alias lintall='cp ~/.jshintignore . ; jshint --verbose . ; rm .jshintignore'
alias csall="find . -not \( -path './node_modules/*' -prune \) -name \*.js | xargs jscs"

# Git Bash aliases node to 'winpty node.exe' which is needed for repl but breaks piping
unalias node &>/dev/null
alias repl='winpty node'

# Git

# Bring these aliases from .gitconfig to global scope
for k in s d a undo rev discard p pf pr pop rba rbm lg; do
	alias $k="git $k"
done

alias st='a && git stash'
alias stpll='st && pr && pop'
alias stpsh='st && pr && p && pop'
alias rbc='a && git rbc'
alias misc='a && git cm "Modified $(git diff --name-only HEAD | grep -Eo ''[^/]+$'')" && p'

# Internet

alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
# Ping one of Google's DNS servers
alias online='ping 8.8.8.8 -t'

# Dotfiles

alias dotfiles='sh -eui ~/dotfiles/install.sh && . ~/.bashrc'