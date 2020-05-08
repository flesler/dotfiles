#!/bin/sh
set -e

# FIXME: SSH private key not used
if [ "$USER" = 'root' ]; then
	USER=$(ls /home | head)
fi

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=ssh://pi@192.168.0.46/media/pi/External/Backup/DeLorean
# export BORG_PASSPHRASE='...'


# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
fatal() { info $*; exit 1; }
trap 'fatal "Backup interrupted"' INT TERM

if [ "$1" = '-i' ]; then
	info "Initializing repo"
	borg init --encryption=repokey-blake2
fi

info "Starting backup"

PREFIX="{hostname}-$USER-"
BORG='sudo --set-home --preserve-env borg'

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

$BORG create       \
  --verbose             \
  --filter AME          \
  --list              \
  --show-rc             \
  --noatime             \
  --compression lz4         \
  --exclude-caches        \
  --exclude '**/.DS_Store' \
  --exclude '**/.git' \
  --exclude '**/.cache' \
  --exclude '**/cache' \
  --exclude '**/Cache' \
  --exclude '**/log' \
  --exclude '**/logs' \
  --exclude '**/node_modules' \
  --exclude '**/tmp' \
  --exclude '*.deb' \
  --exclude '*.log' \
  --exclude '/home/*/.ccache' \
  --exclude '/home/*/.config/Code/*Cache*' \
  --exclude '/home/*/.config/chromium' \
  --exclude '/home/*/.local' \
  --exclude '/home/*/.node-gyp' \
  --exclude '/home/*/.npm/_cacache' \
  --exclude '/home/*/.nvm/versions' \
  --exclude '/home/*/.vscode' \
  --exclude '/home/*/Desktop' \
  --exclude '/home/*/Documents' \
  --exclude '/home/*/Downloads' \
  --exclude '/home/*/Music' \
  --exclude '/home/*/Pictures' \
  --exclude '/home/*/Projects' \
  --exclude '/home/*/Public' \
  --exclude '/home/*/Templates' \
  --exclude '/home/*/Videos' \
  --exclude '/home/*/lost+found' \
  --exclude '/home/*/snap' \
  --exclude '/var/crash' \
  --exclude '/var/lock' \
  --exclude '/var/run' \
  --exclude '/var/spool' \
  --exclude '/var/lib/docker' \
  --exclude '/var/lib/flatpak' \
  --exclude '/var/lib/snapd' \
  --exclude '/root/.config/borg' \
                  \
  $BORG_REPO::"$PREFIX{now:%Y-%m-%dT%H:%M:%S}" \
  /etc              \
  /home               \
  /root               \
  /var              \

if [ $? -ne 0 ]; then
  fatal 'Failed to backup'
fi

if [ "$1" = '-v' ]; then
  info "Checking the integrity of the backup"

  $BORG check $BORG_REPO \
    --verbose \
    --prefix $PREFIX \
    --verify-data \
    --last 1 \

  if [ $? -ne 0 ]; then
    fatal 'Backup successfully but check failed'
  fi
fi

info "Pruning repository"

# Use the `prune` subcommand to maintain 2 daily, 2 weekly and 3 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

$BORG prune              \
  --list              \
  --prefix $PREFIX \
  --show-rc             \
  --save-space           \
  --stats                 \
  --keep-daily  2         \
  --keep-weekly   1         \
  --keep-monthly  1         \

if [ $? -ne 0 ]; then
  fatal 'Backup successfully but prune failed'
fi

info 'Backup and Prune finished successfully'

# Backup /etc too
info 'Backing up /etc to keybase'
cd /etc
sudo git add . && sudo git commit -m 'Updated' && git push origin master
cd - &> /dev/null

exit 0