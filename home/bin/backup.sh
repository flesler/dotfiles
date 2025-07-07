#!/bin/sh
set -e

# FIXME: SSH private key not used
if [ "$USER" = 'root' ]; then
	USER=$(ls /home | head)
fi

# Setting this, so the repo does not need to be given on the command line:
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
  --exclude '**/__pycache__' \
  --exclude '**/.git' \
  --exclude '**/.cache' \
  --exclude '**/cache' \
  --exclude '**/Cache' \
  --exclude '**/CachedData' \
  --exclude '**/History' \
  --exclude '**/venv' \
  --exclude '**/log' \
  --exclude '**/logs' \
  --exclude '**/_logs' \
  --exclude '**/.backup' \
  --exclude '**/node_modules' \
  --exclude '**/tmp' \
  --exclude '**/.insightface' \
  --exclude '**/*Cache*/**' \
  --exclude '**/*cache*/**' \
  --exclude '*.deb' \
  --exclude '*.pyc' \
  --exclude '*.log' \
  --exclude '*.cache' \
  --exclude '*.db' \
  --exclude '*.onnx' \
  --exclude '*.pth' \
  --exclude '*.ckpt' \
  --exclude '*.safetensors' \
  --exclude '*.dat' \
  --exclude '*.dmp' \
  --exclude '*.meta' \
  --exclude '*.raw' \
  --exclude '/home/*/.continue' \
  --exclude '/home/*/bin/*.AppImage' \
  --exclude '/home/*/bin/graphql' \
  --exclude '/home/*/.ccache' \
  --exclude '/home/*/.config/Code/*Cache*' \
  --exclude '/home/*/.config/Code/User' \
  --exclude '/home/*/.config/chromium' \
  --exclude '/home/*/.config/Ledger \Live' \
  --exclude '/home/*/.config/Slack' \
  --exclude '/home/*/.config/joplin-desktop' \
  --exclude '/home/*/.config/VirtualBox' \
  --exclude '/home/*/.config/GraphQL*' \
  --exclude '/home/*/.config/Cursor/User/History' \
  --exclude '/home/*/.config/Cursor/User/workspaceStorage' \
  --exclude '/home/*/Code/manufactured/mfd-logs' \
  --exclude '/home/*/Code/manufactured/mfd-client/public/webviewer' \
  --exclude '/home/*/.local' \
  --exclude '/home/*/.node-gyp' \
  --exclude '/home/*/.npm/_cacache' \
  --exclude '/home/*/.nvm/versions' \
  --exclude '/home/*/.vscode' \
  --exclude '/home/*/Code/easystroke' \
  --exclude '/home/*/Applications' \
  --exclude '/home/*/Desktop' \
  --exclude '/home/*/Documents' \
  --exclude '/home/*/Screencasts' \
  --exclude '/home/*/Downloads' \
  --exclude '/home/*/Music' \
  --exclude '/home/*/Pictures' \
  --exclude '/home/*/Pictures/Screenshot*' \
  --exclude '/home/*/Projects' \
  --exclude '/home/*/Public' \
  --exclude '/home/*/Templates' \
  --exclude '/home/*/Videos' \
  --exclude '/home/*/lost+found' \
  --exclude '/home/*/snap' \
  --exclude '/home/*/miniconda3' \
  --exclude '/home/*/google-cloud-sdk' \
  --exclude '/home/*/cloud-code' \
  --exclude '/home/*/pinokio' \
  --exclude '/home/*/SteamLibrary/steamapps/compatdata' \
  --exclude '/var/crash' \
  --exclude '/var/lock' \
  --exclude '/var/run' \
  --exclude '/var/spool' \
  --exclude '/var/lib/docker' \
  --exclude '/var/lib/flatpak' \
  --exclude '/var/lib/apt' \
  --exclude '/var/lib/snapd' \
  --exclude '/var/lib/dpkg' \
  --exclude '/var/backups' \
  --exclude '/root/.config/borg' \
  --exclude '/var/lib/app-info/icons/ubuntu-focal-universe' \
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
  fatal 'Backup was successful but prune failed'
fi

info 'Backup and prune finished successfully'

# Backup /etc too
# info 'Backing up /etc to keybase'
# cd /etc
# sudo git add . && sudo git commit -m 'Updated' && git push origin master
# cd - &> /dev/null

exit 0