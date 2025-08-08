#!/bin/sh
set -e

# For dry-run, run:
# ~/bin/backup.sh --dry-run 2>&1 | tee /tmp/backup.log

# FIXME: SSH private key not used
if [ "$USER" = 'root' ]; then
	USER=$(ls /home | head)
fi

# Setting this, so the repo does not need to be given on the command line:
export BORG_REPO=ssh://pi@pi.local/mnt/ssd/backups/casius
# export BORG_PASSPHRASE='...'

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
fatal() { info $*; exit 1; }
trap 'fatal "Backup interrupted"' INT TERM

if [ "$1" = '-i' ]; then
	info "Initializing repo"
	borg init --encryption=repokey-blake2
fi

# Check for dry-run option
DRY_RUN=""
if [ "$1" = '--dry-run' ] || [ "$2" = '--dry-run' ]; then
	DRY_RUN="--dry-run"
	info "Running in DRY-RUN mode - no changes will be made"
	info "Will show detailed file processing and pattern matching..."
fi

info "Starting backup"

PREFIX="{hostname}-$USER-"
BORG='sudo --set-home --preserve-env borg'

# List all backups
# $BORG list $BORG_REPO ; exit 0
# Delete one by name
# $BORG delete $BORG_REPO "Casius-flesler-2025-07-29T18:15:37"; exit 0
# Wipe the newest backup (redo it)
# $BORG delete $BORG_REPO --glob-archives "$PREFIX*" --last 1; exit 0

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

$BORG create       \
  --verbose             \
  --filter AME-      \
  --list              \
  --show-rc             \
  $DRY_RUN              \
  --compression lz4         \
  --exclude-caches        \
  --exclude '**/.DS_Store' \
  --exclude '**/__pycache__' \
  --pattern '+ **/.git/config' \
  --pattern '+ **/.git/HEAD' \
  --pattern '- **/.git' \
  --exclude '**/.cache' \
  --exclude '**/cache' \
  --exclude '**/Cache' \
  --exclude '**/CachedData' \
  --exclude '**/History' \
  --exclude '**/venv' \
  --exclude '**/env' \
  --exclude '**/log' \
  --exclude '**/dist' \
  --exclude '**/out' \
  --exclude '**/build' \
  --exclude '**/.next' \
  --exclude '**/logs' \
  --exclude '**/_logs' \
  --exclude '**/.backup' \
  --exclude '**/node_modules' \
  --exclude '**/tmp' \
  --exclude '**/temp' \
  --exclude '**/.insightface' \
  --exclude '**/*Cache*/**' \
  --exclude '**/*cache*/**' \
  --exclude '**/.thumbnails' \
  --exclude '**/.thumbnail' \
  --exclude '**/.trash' \
  --exclude '**/.Trash' \
  --exclude '*.deb' \
  --exclude '*.rpm' \
  --exclude '*.dmg' \
  --exclude '*.iso' \
  --exclude '*.img' \
  --exclude '*.pyc' \
  --exclude '*.pyo' \
  --exclude '*.log' \
  --exclude '*.cache' \
  --exclude '*.db' \
  --exclude '*.sqlite' \
  --exclude '*.sqlite3' \
  --exclude '*.onnx' \
  --exclude '*.pth' \
  --exclude '*.ckpt' \
  --exclude '*.safetensors' \
  --exclude '*.dat' \
  --exclude '*.dmp' \
  --exclude '*.meta' \
  --exclude '*.raw' \
  --exclude '*.bin' \
  --exclude '*.tmp' \
  --exclude '*.map' \
  --exclude '*.swp' \
  --exclude '*.bak' \
  --exclude '*.desktop' \
  --exclude '*.txt.xz' \
  --exclude '*.org.chromium.Chromium*' \
  --exclude '*~' \
  --exclude '/home/*/bin/*.AppImage' \
  --exclude '/home/*/.ccache' \
  --exclude '/home/*/.rustup' \
  --exclude '/home/*/.lmstudio' \
  --exclude '/home/*/.config/Code/*Cache*' \
  --exclude '/home/*/.config/Code/User' \
  --exclude '/home/*/.config/chromium' \
  --exclude '/home/*/.config/google-chrome' \
  --exclude '/home/*/.config/Ledger \Live' \
  --exclude '/home/*/.config/Slack' \
  --exclude '/home/*/.config/joplin-desktop' \
  --exclude '/home/*/.config/VirtualBox' \
  --exclude '/home/*/.config/GraphQL*' \
  --exclude '/home/*/.config/Cursor/User/History' \
  --exclude '/home/*/.config/Cursor/User/workspaceStorage' \
  --exclude '/home/*/.config/Cursor/CachedExtensions' \
  --exclude '/home/*/.config/Cursor/logs' \
  --exclude '/home/*/.config/discord' \
  --exclude '/home/*/.config/zoom' \
  --exclude '/home/*/.config/teams' \
  --exclude '/home/*/Code/manufactured/mfd-logs' \
  --exclude '/home/*/Code/manufactured/mfd-client/public/webviewer' \
  --exclude '/home/*/Code/dictation/downloads/' \
  --exclude '/home/*/.local/share/Trash' \
  --exclude '/home/*/.local/share/Steam' \
  --exclude '/home/*/.local/share/virtualenvs' \
  --exclude '/home/*/.node-gyp' \
  --exclude '/home/*/.npm/_cacache' \
  --exclude '/home/*/.nvm/versions' \
  --exclude '/home/*/.vscode' \
  --exclude '/home/*/.cursor' \
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
  --exclude '/home/*/anaconda3' \
  --exclude '/home/*/google-cloud-sdk' \
  --exclude '/home/*/cloud-code' \
  --exclude '/home/*/pinokio' \
  --exclude '/home/*/.docker' \
  --exclude '/home/*/.kube' \
  --exclude '/home/*/.eclipse' \
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
  --exclude '/var/lib/swcatalog' \
  --exclude '/var/backups' \
  --exclude '/var/cache' \
  --exclude '/var/tmp' \
  --exclude '/var/lib/app-info/icons/ubuntu-focal-universe' \
  --exclude '/var/lib/samba/private/msg.sock' \
  --exclude '/etc/alternatives' \
  --exclude '/etc/brltty' \
  --exclude '/root/.config/borg' \
  --exclude '/root/snap' \
  $BORG_REPO::"$PREFIX{now:%Y-%m-%dT%H:%M:%S}" \
  /etc              \
  /home               \
  /root               \
  /var              \
  /opt/dnscrypt-proxy   \

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

if [ -z "$DRY_RUN" ]; then
  info "Pruning repository"

  # Use the `prune` subcommand to maintain 2 daily, 1 weekly and 1 monthly
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
else
  info "Skipping prune (dry-run mode)"
fi

info 'Backup and prune finished successfully'

exit 0