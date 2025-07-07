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
# alias trash='gio trash'
#alias rm=trash
alias mkp='mkdir -p'
alias path.list='echo "$PATH" | tr ":" "\n"'
alias t='tldr --theme ocean'
alias find.dir='find . -type d -iname'
alias find.file='find . -type f -iname'
alias find.inside='grep --exclude-dir={node_modules,.git} -Irlw . -e'
alias find.gzip='find . -iname '''*.gz''' | sort | xargs gzip -dc | grep -Eie'
alias restart='sudo shutdown -r now'

# FD
alias fd=fdfind
alias fd.glob='fdfind --glob'
alias fd.str='fdfind --fixed-strings'
alias fd.ext='fdfind -e'

# Dust
alias du.s='dust -X node_modules -X .git -n 35'
alias du.flat='du.s -d1'
alias du.big='du.s -p -F -z 10M'

# Node.js

alias ns='node server'
alias na='node app'
alias r='npm run -s'
alias ni='npm install'
alias nid='npm install -D'
alias nu='nvm use'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "process.argv[1] ? new Date(+(process.argv[1]+'\''000'\'').slice(0,13)).toISOString() : Date.now()" -- '

# Git

alias g=git

# Bring these aliases from .gitconfig to global scope
for k in s d a p pf pr pop rba rbi lg rhh rh1 rs1 stu stl stc l1 bb; do
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
alias rbd='git co dev && pr && git co - && git rb dev'
alias rdb=rbd
alias rbp='git co prod && pr && git co - && git rb prod'
alias rpb=rbp
alias rbbranch='git rebase -i $(git merge-base $(git rev-parse --abbrev-ref HEAD) master)'
alias misc='a && git cm "Modified $(git diff --name-only HEAD | grep -Eo ''[^/]+$'')" && p'
alias last_commit='git log -1 --pretty=%B | clip'
#alias first_foreign_commit='git log --graph --pretty=format:"%h %an" | grep -vi "$(git config user.name)" | head -n1 | cut -d" " -f1'
alias first_foreign_commit='git rev-list --boundary ...master | grep "^-" | cut -c2- | tail -n1'
alias rbmine='git rebase -i $(first_foreign_commit)'
alias set_upstream='git branch --set-upstream-to=origin/$(git rev-parse --abbrev-ref HEAD) $(git rev-parse --abbrev-ref HEAD)'
alias git_gc='git fetch --prune && git fsck --unreachable && git reflog expire --expire=now --all && git gc --prune=now --aggressive'
alias git_delete_other_branches="git fetch -p && git branch | grep -ve '*' -e master -e main -e dev -e stg -e prod | xargs git branch -d" # --force
alias todev='git co dev && pr && git fp && git_delete_other_branches -f; git_gc'
alias toprod='git co prod && pr && git fp && git_delete_other_branches -f; git_gc'
alias tomain='git co main && pr && git fp && git_delete_other_branches -f; git_gc'
# If I had another file descriptor watcher leak, check which processes are hoarding
alias watchers="sudo lsof -n | grep inotify | awk '{print $1}' | sort | uniq -c | sort -rn"

# Internet

alias localip='hostname -I | awk '\''{print $1}'\'''
# alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
# Ping one of Google's DNS servers
alias online='ping 8.8.8.8'
# Ping a domain to also check DNS resolution
alias onlined='ping google.com'
alias dns.blocked="tail -n99 /opt/dnscrypt-proxy/blocked.log | awk '{print \$1,\$2,\$4,\$5}' | sort -r | awk '!a[\$3]++' | sort"
alias dns.restart='sudo systemctl restart dnscrypt-proxy.service'
alias dns.whitelist='code /opt/dnscrypt-proxy/domain-whitelist.txt --wait && dns.restart'
alias dns.blacklist='code /opt/dnscrypt-proxy/blacklist.txt --wait && dns.restart'
alias dns.config='code /opt/dnscrypt-proxy/dnscrypt-proxy.toml --wait && dns.restart'
alias dns.clear='for f in /opt/dnscrypt-proxy/*.log; do echo "" | sudo tee "$f"; done'
alias dns.logs='sudo journalctl -u dnscrypt-proxy.service'
alias dns.enable='sudo cp /etc/resolv.conf.override /etc/resolv.conf'
alias dns.disable='sudo cp /etc/resolv.conf.bkp /etc/resolv.conf'
alias dns.pihole='sudo cp /etc/resolv.conf.pihole /etc/resolv.conf'
# DNS
alias wifi.on='sudo rfkill unblock wifi && sudo ip link set wlan0 up'
alias wifi.off='sudo ip link set wlan0 down'
# Ollama
alias ollama.restart='sudo systemctl restart ollama'
alias ollama.stop='sudo systemctl stop ollama'
alias ollama.logs='sudo journalctl -u ollama.service'
alias ollama.update='curl -fsSL https://ollama.com/install.sh | sudo sh && ollama --version'
# History (history.forget is in .bash_functions)
alias history.restore='cp ~/.bash_history.bkp ~/.bash_history'
alias history.grep='history | grep'
alias history.forget='forget'
alias history.edit='code ~/.bash_history'
# Keyboard
alias keyboard.keys="xev | grep -A2 --line-buffered '^KeyRelease' | sed -n '/keycode /s/^.*keycode \([0-9]*\).* (.*, \(.*\)).*$/\1 \2/p'"
alias keyboard.dump='sleep 1; xdotool type "$(xclip -o -selection clipboard)"'
# Other

# Add an "alert" alias for long running commands. Use like so: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias reload='source ~/.bashrc'
alias dotfiles.sync='find ~ -maxdepth 1 -type f -mtime -1 | grep -e git -e bash | grep -ve history -e extras | parallel cp {} ~/Backup/Home/dotfiles/home; cp ~/bin/*.sh ~/Backup/Home/dotfiles/home/bin'
# Extract prompt from an image
alias prompt="identify -format '%[parameters]'"

alias snap.i='snap install'
alias snap.r='snap refresh'

alias apt.i='sudo apt update -y && sudo apt install -y'
alias apt.u='sudo apt update -y && sudo apt upgrade -y'

# Rsync
alias rs='rsync -av --progress --no-owner --no-group --open-noatime --human-readable --acls'
alias rs.cp='rs --delete'
alias rs.dry='rs.cp --dry-run'
# Leaves empty dirs, use `find $path -type d -empty -delete`
alias rs.mv='rs --remove-source-files'

# For the RaspberryPI
alias pi.home='rs ~/.{bash_{aliases,functions,profile,options,exports,prompt,login,logout,extras},profile,gitconfig,npmrc,bashrc} rsync://pi.local/home'

# GPU
alias gpu.usage='nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv'