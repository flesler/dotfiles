snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do sudo snap remove "$snapname" --revision="$revision"; done
flatpak uninstall --unused -y
docker system prune -a --force && docker container prune --force --filter "until=24h" && docker volume prune --force && docker image prune -a --force --filter "until=24h" && docker network prune --force --filter "until=24h"
sudo apt autoremove -y && sudo apt clean -y
# Clean old Kernels
# sudo apt-get purge $(dpkg -l linux-{image,headers}-"[0-9]*" | awk '/ii/{print $2}' | grep -ve "$(uname -r | sed -r 's/-[a-z]+//')")
