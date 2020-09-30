# Shell

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias b='cd -'
alias ~='cd ~'
alias zz='z -c'
alias rr='rm -r'
alias rrf='rr -f'
alias mkp='mkdir -p'
alias path.list='echo "$PATH" | tr ":" "\n"'
alias find.dir='find . -type d -iname'
alias find.file='find . -type f -iname'
alias restart='sudo shutdown -r now'

# Node.js

alias ns='node server'
alias na='node app'
alias n10='nvm run v10.16.3'
alias n12='nvm run v12.16.1'
alias prod='NODE_ENV=production'
alias r='npm run -s'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "new Date(+(process.argv[1]+'\''000'\'').slice(0,13)).toISOString()" -- '

# Git

alias g=git

# Bring these aliases from .gitconfig to global scope
for k in s d a p pf pr pop rba rbi lg rhh rh1 rs1 stu  stl stc l1; do
	alias $k="git $k"
done

for k in st cmnv rbc ame amne; do
	alias $k="a && git $k"
done

alias stpll='st && pr && pop'
alias stpsh='st && pr && p && pop'
# alias rbm='_br_=$(git rev-parse --abbrev-ref HEAD) && git co master && pr && git co $_br_ && git rebase master'
# alias rbm='git fetch -p && git rebase origin/master'
alias rbm='git com && pr && git co - && git rbm'
alias rbbranch='git rebase -i $(git merge-base $(git rev-parse --abbrev-ref HEAD) master)'
alias misc='a && git cm "Modified $(git diff --name-only HEAD | grep -Eo ''[^/]+$'')" && p'
alias last_commit='git log -1 --pretty=%B | clip'
#alias first_foreign_commit='git log --graph --pretty=format:"%h %an" | grep -vi "$(git config user.name)" | head -n1 | cut -d" " -f1'
alias first_foreign_commit='git rev-list --boundary ...master | grep "^-" | cut -c2- | tail -n1'
alias rbmine='git rebase -i $(first_foreign_commit)'
alias set_upstream='git branch --set-upstream-to=origin/$(git rev-parse --abbrev-ref HEAD) $(git rev-parse --abbrev-ref HEAD)'
alias git_gc='git fetch --prune && git fsck --unreachable && git reflog expire --expire=now --all && git gc --prune=now --aggressive'
alias git_delete_other_branches="git fetch -p && git branch | grep -ve '*' -e master | xargs git branch -d" # --force

# Internet

alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
# Ping one of Google's DNS servers
alias online='ping 8.8.8.8'
# Ping a domain to also check DNS resolution
alias onlined='ping google.com'
alias dns.blocked='tail -n99 -f /etc/dnscrypt-proxy/blocked.log | uniq -f 3'
alias dns.queries='tail -n99 -f /etc/dnscrypt-proxy/query.log | uniq -f 6'
alias dns.restart='sudo systemctl restart dnscrypt-proxy.service'
alias dns.whitelist='code /etc/dnscrypt-proxy/domain-whitelist.txt --wait && dns.restart'

# Other

# Add an "alert" alias for long running commands. Use like so: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias sai='sudo apt install -y'
alias sau='sudo apt update -y && sudo apt upgrade -y'
alias reload='source ~/.bashrc'
alias dotfiles.sync='find ~ -maxdepth 1 -type f -mtime -1 | grep -e git -e bash | parallel cp {} /media/flesler/Data/Backup/Home/dotfiles/home'
