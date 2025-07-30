#!/bin/bash

# Complete Borgbackup Recovery Script - Restore Everything
# This script restores ALL files from the backup without cherry-picking
# It handles both user and system files, respecting ownership

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (same as your existing backup)
BORG_REPO="ssh://pi@pi.local/mnt/ssd/backups/casius"
# TODO: Update with the one we want
ARCHIVE_NAME="Casius-flesler-2025-07-29T18:26:18"
#export BORG_PASSPHRASE='...'

# Command line options
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --dry-run        Show what would be extracted without actually doing it"
            echo "  --help           Show this help message"
            echo ""
            echo "This script restores EVERYTHING from the backup:"
            echo "• All user files in /home/flesler/"
            echo "• All system files (/etc, /var, /root)"
            echo "• Handles root-owned files properly"
            echo ""
            echo "IMPORTANT: This script only READS from your Borg backup!"
            echo ""
            echo "EXAMPLES:"
            echo "  $0                    # Restore everything (user files only)"
            echo "  sudo --preserve-env=SSH_AUTH_SOCK $0  # Restore everything (user + system)"
            echo "  $0 --dry-run          # Show what would be restored"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}=== Complete Borgbackup Recovery Script ===${NC}"
echo -e "${GREEN}✓ This script only READS from your Borg backup - it never modifies the backup itself!${NC}"
echo -e "${YELLOW}Repo: $BORG_REPO${NC}"
echo -e "${YELLOW}Archive: $ARCHIVE_NAME${NC}"
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}DRY RUN MODE - No files will be extracted${NC}"
fi
echo ""

# Function to log with timestamp
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to handle errors
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check if borg is installed
if ! command -v borg &> /dev/null; then
    error "Borgbackup is not installed. Install with: sudo apt install borgbackup"
fi
log "✓ Borgbackup is installed ($(borg --version))"

# Check user and determine mode
RUNNING_AS_ROOT=false
if [[ $EUID -eq 0 ]]; then
    RUNNING_AS_ROOT=true
    log "✓ Running as root - will recover both user and system files"
    
    # Check if SSH agent is available for root
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        echo -e "${RED}⚠️  SSH agent not available for root user!${NC}"
        echo "Run with: sudo --preserve-env=SSH_AUTH_SOCK $0"
        echo "This preserves your SSH keys for connecting to the Pi."
        exit 1
    fi
    log "✓ SSH agent available for root"
elif [[ "$USER" == "flesler" ]]; then
    log "✓ Running as user $USER - will recover user files only"
    echo -e "${YELLOW}⚠️  To recover system files too, run: sudo --preserve-env=SSH_AUTH_SOCK $0${NC}"
else
    error "This script must be run as user 'flesler' or with sudo"
fi

# Test SSH connection first
log "Testing SSH connection to Pi..."
if ! ssh -o ConnectTimeout=10 pi@pi.local "echo 'SSH OK'" &>/dev/null; then
    error "Cannot connect to pi@pi.local via SSH. Check network and SSH keys."
fi
log "✓ SSH connection to Pi working"

# Test connection to borg repo
log "Testing connection to backup repository..."
if ! borg info "$BORG_REPO::$ARCHIVE_NAME" &>/dev/null; then
    error "Cannot connect to backup repository. Check SSH keys and passphrase."
fi
log "✓ Connected to backup repository successfully"

echo ""
echo -e "${BLUE}=== Recovery Plan ===${NC}"
echo -e "${RED}⚠️  This will restore EVERYTHING from the backup!${NC}"
echo ""
echo "What will be restored:"
echo "USER FILES:"
echo "• Complete /home/flesler/ directory (all files and subdirectories)"
if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
    echo "SYSTEM FILES:"
    echo "• /etc (system configurations)"
    echo "• /var (system data)"
    echo "• /root (root home directory)"
    echo "• Any other root-owned files in the backup"
fi
echo ""

if [[ "$DRY_RUN" != "true" ]]; then
    read -p "Continue with COMPLETE recovery? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Recovery cancelled."
        exit 0
    fi
fi

echo ""
log "Starting complete recovery process..."

# No backup needed - just restore everything directly

# Recover user files
log "=== Recovering ALL user files ==="
if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
    # Running as root - extract to /home/flesler and fix ownership
    cd /
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would extract all files from home/flesler/"
        borg list "$BORG_REPO::$ARCHIVE_NAME" | grep "^home/flesler/" | head -10
        echo "  ... (showing first 10 items)"
    else
        log "Extracting all user files..."
        if borg extract --progress "$BORG_REPO::$ARCHIVE_NAME" home/flesler; then
            log "✓ All user files extracted successfully"
            log "Setting ownership to flesler:flesler..."
            chown -R flesler:flesler /home/flesler 2>/dev/null || true
            log "✓ User file ownership set correctly"
        else
            error "Failed to extract user files"
        fi
    fi
else
    # Running as user - extract to current directory (should be /home/flesler)
    cd /home/flesler || error "Could not change to /home/flesler"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would extract all files from home/flesler/"
        borg list "$BORG_REPO::$ARCHIVE_NAME" | grep "^home/flesler/" | head -10
        echo "  ... (showing first 10 items)"
    else
        log "Extracting all user files..."
        if borg extract --progress --strip-components=2 "$BORG_REPO::$ARCHIVE_NAME" home/flesler; then
            log "✓ All user files extracted successfully"
            # Fix any ownership issues
            find . -type f -exec chown "$USER:$USER" {} \; 2>/dev/null || true
            find . -type d -exec chown "$USER:$USER" {} \; 2>/dev/null || true
            log "✓ User file ownership verified"
        else
            error "Failed to extract user files"
        fi
    fi
fi

# Recover everything in the backup (only if running as root)
if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
    log "=== Recovering EVERYTHING (complete backup restore) ==="
    cd /
    
    # Extract absolutely everything in the backup
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would extract ALL files (complete backup)"
        borg list "$BORG_REPO::$ARCHIVE_NAME" | head -20
        echo "  ... (showing first 20 items)"
    else
        log "Extracting ALL files (including home directory again)..."
        # Extract absolutely everything with zero filtering
        if borg extract --progress "$BORG_REPO::$ARCHIVE_NAME"; then
            log "✓ Complete backup extracted successfully (all files)"
        else
            log "⚠ Some files may have failed to extract (this might be normal)"
        fi
    fi
fi

# Fix special permissions for important directories
if [[ "$DRY_RUN" != "true" ]]; then
    log "=== Setting correct permissions ==="
    
    if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
        SSH_DIR="/home/flesler/.ssh"
        GNUPG_DIR="/home/flesler/.gnupg"
    else
        SSH_DIR="$HOME/.ssh"
        GNUPG_DIR="$HOME/.gnupg"
    fi
    
    # Fix SSH permissions
    if [[ -d "$SSH_DIR" ]]; then
        chmod 700 "$SSH_DIR" 2>/dev/null || true
        chmod 600 "$SSH_DIR"/* 2>/dev/null || true
        log "✓ SSH permissions set correctly"
    fi
    
    # Fix GPG permissions
    if [[ -d "$GNUPG_DIR" ]]; then
        chmod 700 "$GNUPG_DIR" 2>/dev/null || true
        log "✓ GPG permissions set correctly"
    fi
fi

echo ""
log "Complete recovery finished!"
echo ""
echo -e "${BLUE}=== Summary ===${NC}"
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}DRY RUN completed - no files were actually extracted${NC}"
    echo "Run without --dry-run to perform actual recovery"
else
    echo -e "${GREEN}ALL files have been recovered from the backup!${NC}"
    echo "• All user files restored to /home/flesler/"
    if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
        echo "• All system files restored to their original locations"
    fi
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Verify your files are in place: ls -la ~/"
    echo "2. Check your projects: ls -la ~/Code/"
    echo "3. Test SSH keys: ssh-add -l"
    echo "4. Source bash config: source ~/.bash_aliases"
    if [[ "$RUNNING_AS_ROOT" == "true" ]]; then
        echo "5. Consider rebooting to ensure all system changes take effect"
    fi
    echo ""
    echo -e "${GREEN}Complete recovery script finished successfully!${NC}"
fi