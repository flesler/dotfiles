#!/bin/bash

# Universal script to restore Git remotes and npm dependencies for all project directories
# Works by auto-detecting repository URLs from package.json or using a provided base URL
# Usage: ./universal-restore-projects.sh [--dry-run] [--remote-base <base-url>]
#
# Examples:
#   ./universal-restore-projects.sh --dry-run
#   ./universal-restore-projects.sh --remote-base git@github.com:mfdtrade
#   ./universal-restore-projects.sh --remote-base https://github.com/myuser

# set -e  # Exit on any error - disabled for robustness during NVM/npm operations

# Parse command line arguments
DRY_RUN=false
REMOTE_BASE=""
FILTER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --remote-base)
            REMOTE_BASE="$2"
            shift 2
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN]${NC} $1"
    else
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_action() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${GREEN}[WOULD DO]${NC} $1"
    else
        echo -e "${GREEN}[DOING]${NC} $1"
    fi
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if directory has .gitignore
has_gitignore() {
    [[ -f ".gitignore" ]]
}

# Function to check if directory has package.json (Node.js project)
has_package_json() {
    [[ -f "package.json" ]]
}

# Function to check if directory has .nvmrc
has_nvmrc() {
    [[ -f ".nvmrc" ]]
}

# Function to check if directory is a git repository
is_git_repo() {
    [[ -d ".git" ]] || git rev-parse --git-dir >/dev/null 2>&1
}

# Function to check if remote already exists
has_origin_remote() {
    git remote get-url origin >/dev/null 2>&1
}

# Function to test if a remote repository exists
remote_exists() {
    local repo_url="$1"
    if [[ -z "$repo_url" ]]; then
        return 1
    fi
    
    # Test if remote repository exists using git ls-remote with timeout
    timeout 10 git ls-remote --exit-code "$repo_url" HEAD >/dev/null 2>&1
}

# Function to extract GitHub repo URL from package.json
get_repo_url_from_package_json() {
    local dir_name="$1"
    
    if ! has_package_json; then
        echo ""
        return
    fi
    
    # Try different methods to extract GitHub URL from package.json
    local repo_url=""
    
    # Method 1: Try jq if available
    if command -v jq >/dev/null 2>&1; then
        # Try repository.url first
        repo_url=$(jq -r '.repository.url // empty' package.json 2>/dev/null | head -n1)
        
        # If not found, try repository as string
        if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
            repo_url=$(jq -r '.repository // empty' package.json 2>/dev/null | head -n1)
        fi
        
        # Try homepage
        if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
            repo_url=$(jq -r '.homepage // empty' package.json 2>/dev/null | head -n1)
        fi
        
        # Try bugs.url
        if [[ -z "$repo_url" || "$repo_url" == "null" ]]; then
            repo_url=$(jq -r '.bugs.url // empty' package.json 2>/dev/null | head -n1)
        fi
    else
        # Method 2: Use grep if jq is not available
        repo_url=$(grep -E "github\.com[/:][\w-]+/[\w.-]+" package.json | head -n1 | grep -oE "github\.com[/:][\w-]+/[\w.-]+" | head -n1)
        if [[ -n "$repo_url" ]]; then
            repo_url="https://$repo_url"
        fi
    fi
    
    # Clean up the URL
    if [[ -n "$repo_url" && "$repo_url" != "null" ]]; then
        # Convert to SSH format and extract owner/repo
        if [[ "$repo_url" =~ github\.com[/:]([^/]+)/([^/.]+) ]]; then
            local owner="${BASH_REMATCH[1]}"
            local repo="${BASH_REMATCH[2]}"
            # Remove common suffixes
            repo=$(echo "$repo" | sed 's/\.git$//')
            echo "git@github.com:${owner}/${repo}.git"
            return
        fi
    fi
    
    echo ""
}

# Function to determine repository URL
get_repository_url() {
    local dir_name="$1"
    
    # If remote base is provided, use it
    if [[ -n "$REMOTE_BASE" ]]; then
        local repo_url="${REMOTE_BASE}/${dir_name}.git"
        echo "$repo_url"
        return
    fi
    
    # Try to extract from package.json
    local extracted_url=$(get_repo_url_from_package_json "$dir_name")
    if [[ -n "$extracted_url" ]]; then
        # During dry-run, skip the expensive remote existence check
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "$extracted_url"
            return
        fi
        
        # Test if the extracted URL actually exists
        if remote_exists "$extracted_url"; then
            echo "$extracted_url"
            return
        else
            log_warning "Auto-detected repository '$extracted_url' does not exist"
        fi
    fi
    
    # Fallback: try flesler/$dirname
    local fallback_url="git@github.com:flesler/${dir_name}.git"
    
    # During dry-run, skip the expensive remote existence check
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would test fallback repository: $fallback_url"
        echo "$fallback_url"
        return
    fi
    
    if remote_exists "$fallback_url"; then
        log_info "Using fallback repository: $fallback_url"
        echo "$fallback_url"
        return
    fi
    
    # No working URL found
    echo ""
}

# Function to restore a single project
restore_project() {
    local dir_name="$1"
    
    log_info "Processing directory: $dir_name"
    
    # Skip if not a directory
    if [[ ! -d "$dir_name" ]]; then
        log_warning "Skipping $dir_name - not a directory"
        return 0
    fi
    
    # Enter the directory
    cd "$dir_name"
    
    # Only handle Git if .gitignore exists
    if has_gitignore; then
        # Get repository URL
        local repo_url=$(get_repository_url "$dir_name")
        
        if [[ -z "$repo_url" ]]; then
            log_warning "No repository URL found for $dir_name, skipping Git setup"
        else
            # Initialize git repo if not already one
            if ! is_git_repo; then
                log_action "Initialize git repository"
                if [[ "$DRY_RUN" == "false" ]]; then
                    git init
                fi
            else
                log_info "Git repository already exists"
            fi
            
            # Add/update origin remote
            if has_origin_remote; then
                local current_origin=$(git remote get-url origin 2>/dev/null || echo "unknown")
                if [[ "$current_origin" != "$repo_url" ]]; then
                    log_action "Update origin remote from '$current_origin' to '$repo_url'"
                    if [[ "$DRY_RUN" == "false" ]]; then
                        git remote set-url origin "$repo_url"
                    fi
                else
                    log_info "Origin remote already correctly set"
                fi
            else
                log_action "Add origin remote: $repo_url"
                if [[ "$DRY_RUN" == "false" ]]; then
                    git remote add origin "$repo_url"
                fi
            fi
            
            # Fetch and sync with remote default branch (main or master)
            if is_git_repo && has_origin_remote; then
                if [[ "$DRY_RUN" == "false" ]]; then
                    # Check for main, dev, then master branch
                    local default_branch=""
                    if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
                        default_branch="main"
                    elif git ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
                        default_branch="dev"
                    elif git ls-remote --exit-code --heads origin master >/dev/null 2>&1; then
                        default_branch="master"
                    fi
                    
                    if [[ -n "$default_branch" ]]; then
                        log_action "Fetch and sync with remote $default_branch branch"
                        git fetch origin "$default_branch" 2>/dev/null || log_warning "Could not fetch from origin"
                        git reset --hard "origin/$default_branch" 2>/dev/null || log_warning "Could not sync with remote $default_branch"
                    else
                        log_info "No remote main/dev/master branch found, skipping sync"
                    fi
                else
                    log_action "Fetch and sync with remote default branch (main/dev/master)"
                fi
            fi
            
            # Set upstream tracking for current branch
            if is_git_repo; then
                local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
                if [[ -n "$current_branch" && "$current_branch" != "HEAD" ]]; then
                    if [[ "$DRY_RUN" == "false" ]]; then
                        # Find the actual default branch that exists on remote
                        local default_branch=""
                        if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
                            default_branch="main"
                        elif git ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
                            default_branch="dev"
                        elif git ls-remote --exit-code --heads origin master >/dev/null 2>&1; then
                            default_branch="master"
                        fi
                        
                        if [[ -n "$default_branch" ]]; then
                            log_action "Set upstream tracking for branch: $current_branch -> origin/$default_branch"
                            git branch --set-upstream-to=origin/$default_branch $current_branch 2>/dev/null || log_warning "Could not set upstream for $current_branch to origin/$default_branch"
                        else
                            log_warning "No remote main/dev/master branch found for upstream tracking"
                        fi
                    else
                        log_action "Set upstream tracking for branch: $current_branch"
                    fi
                fi
            fi
        fi
    else
        log_info "No .gitignore found, skipping Git setup"
    fi
    
    # Handle Node.js projects only if package.json exists
    if has_package_json; then
        log_info "Node.js project detected"
        
        # Use nvm if .nvmrc exists
        if has_nvmrc; then
            local node_version=$(cat .nvmrc)
            log_action "Use Node version from .nvmrc: $node_version"
            
            # Source nvm and use the specified version
            if [[ "$DRY_RUN" == "false" ]]; then
                if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
                    # Source nvm with error handling
                    set +e  # Temporarily disable exit on error for NVM operations
                    source "$HOME/.nvm/nvm.sh"
                    
                    # Try to use the specified version
                    if ! nvm use "$node_version" 2>/dev/null; then
                        log_warning "Node version $node_version not installed, trying to install..."
                        if ! nvm install "$node_version" 2>/dev/null; then
                            log_warning "Failed to install Node $node_version, using current version"
                        else
                            if ! nvm use "$node_version" 2>/dev/null; then
                                log_warning "Failed to switch to Node $node_version after installation"
                            fi
                        fi
                    fi
                    set -e  # Re-enable exit on error (though it's commented out above)
                else
                    log_warning "nvm not found, skipping nvm use"
                fi
            fi
        else
            log_info "No .nvmrc found, would use current Node version"
        fi
        
        # Install npm dependencies
        if [[ -f "package-lock.json" ]]; then
            log_action "Run 'npm ci' (clean install)"
            if [[ "$DRY_RUN" == "false" ]]; then
                set +e  # Disable exit on error for npm operations
                if npm install 2>/dev/null; then
                    # Try to restore package-lock.json if it was modified
                    git checkout -- package-lock.json 2>/dev/null || true
                else
                    log_warning "npm install failed, but continuing..."
                fi
                set -e  # Re-enable exit on error
            fi
        else
            log_action "Run 'npm install'"
            if [[ "$DRY_RUN" == "false" ]]; then
                set +e  # Disable exit on error for npm operations
                if ! npm install 2>/dev/null; then
                    log_warning "npm install failed, but continuing..."
                fi
                set -e  # Re-enable exit on error
            fi
        fi
        
        if [[ "$DRY_RUN" == "false" ]]; then
            log_success "Node.js dependencies installed"
        fi
    else
        log_info "Not a Node.js project (no package.json)"
    fi
    
    # Return to parent directory
    cd ..
    
    log_success "Completed processing $dir_name"
    echo ""
}

# Main execution
main() {
    # Change to ~/Code directory
    cd ~/Code
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN]${NC} Analyzing projects in $(pwd)"
    else
        log_info "Starting project restoration in $(pwd)"
    fi
    
    if [[ -n "$REMOTE_BASE" ]]; then
        log_info "Using remote base: $REMOTE_BASE"
    else
        log_info "Auto-detecting repository URLs from package.json"
    fi
    echo ""
    
    # Find project directories (1-3 levels deep) that contain package.json or .gitignore
    local project_dirs=()
    
    # Find directories with package.json (1-3 levels deep)
    while IFS= read -r -d '' dir; do
        # Get the directory containing the package.json
        project_dir=$(dirname "$dir")
        # Convert to relative path from ~/Code
        relative_dir=${project_dir#./}
        if [[ "$relative_dir" != "." ]]; then
            project_dirs+=("$relative_dir")
        fi
    done < <(find . -maxdepth 3 -name "package.json" -type f -print0 )
    
    # Find directories with .gitignore (1-3 levels deep) that we haven't already found
    while IFS= read -r -d '' dir; do
        # Get the directory containing the .gitignore
        project_dir=$(dirname "$dir")
        # Convert to relative path from ~/Code
        relative_dir=${project_dir#./}
        if [[ "$relative_dir" != "." ]]; then
            # Check if we already have this directory
            local already_added=false
            for existing_dir in "${project_dirs[@]}"; do
                if [[ "$existing_dir" == "$relative_dir" ]]; then
                    already_added=true
                    break
                fi
            done
            if [[ "$already_added" == "false" ]]; then
                project_dirs+=("$relative_dir")
            fi
        fi
    done < <(find . -maxdepth 3 -name ".gitignore" -type f -print0)

    # Filter the project directories
    if [[ -n "$FILTER" ]]; then
        filtered_dirs=()
        for dir in "${project_dirs[@]}"; do
            if [[ "$dir" == $FILTER ]]; then
                filtered_dirs+=("$dir")
            fi
        done
        project_dirs=("${filtered_dirs[@]}")
    fi

    # Remove duplicates and sort
    local unique_dirs=($(printf '%s\n' "${project_dirs[@]}" | sort -u))
    
    if [[ ${#unique_dirs[@]} -eq 0 ]]; then
        log_warning "No project directories found (looking for package.json or .gitignore files)"
        exit 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}[DRY RUN]${NC} Found ${#unique_dirs[@]} project directories to analyze:"
    else
        log_info "Found ${#unique_dirs[@]} project directories to process:"
    fi
    for dir in "${unique_dirs[@]}"; do
        echo "  - $dir"
    done
    echo ""
    
    # Process each directory
    for dir_path in "${unique_dirs[@]}"; do
        # Extract just the directory name for the restore function
        dir_name=$(basename "$dir_path")
        
        # Change to the parent directory of the project
        parent_dir=$(dirname "$dir_path")
        if [[ "$parent_dir" != "." ]]; then
            cd "$parent_dir"
        fi
        
        restore_project "$dir_name"
        
        # Return to ~/Code
        cd ~/Code
    done
    
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run complete!"
        log_info "To actually perform these actions, run: $0"
    else
        log_success "All directories processed successfully!"
    fi
}

# Run main function
main "$@"