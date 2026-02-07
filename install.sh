#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Script version
SCRIPT_VERSION="0.1.0"

# Colors with fallback for terminals without color support
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    # Fallback for terminals without color support
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

# Simple logging
log() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; }
warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1" >&2; }

# Get latest version from GitHub API
get_latest_version() {
    local api_url="https://api.github.com/repos/seishio/homebrew-logparser/releases/latest"
    local response
    local fallback_version="0.4.30"
    
    if ! response=$(timeout 10s curl -s "$api_url" 2>/dev/null); then
        echo "$fallback_version"
        return 0
    fi
    
    local version=$(echo "$response" | grep -Po '"tag_name": "v\K[^"]*' 2>/dev/null || echo "")
    if [[ -z "$version" ]]; then
        echo "$fallback_version"
    else
        echo "$version"
    fi
}

# Determine version
VERSION="${1:-$(get_latest_version)}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid version: $VERSION"
    exit 1
fi

# Check required tools
check_tools() {
    local missing_tools=()
    for tool in curl timeout; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}

# Check sudo availability
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log "sudo access required for package installation"
        # Check if running in non-interactive mode
        if [[ -t 0 ]]; then
            # Interactive mode - can ask for password
            if ! sudo -v; then
                error "sudo access denied"
                exit 1
            fi
        else
            # Non-interactive mode - cannot ask for password
            error "sudo access required but running in non-interactive mode"
            error "Please run with sudo or ensure passwordless sudo is configured"
            exit 1
        fi
    fi
}

# Check network connectivity
check_network() {
    if ! timeout 5s ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        error "No network connectivity"
        exit 1
    fi
}

# Show download progress
show_progress() {
    local file="$1"
    local url="$2"
    
    # Check if file already exists and is not empty
    if [[ -f "$file" ]] && [[ -s "$file" ]]; then
        log "File $file already exists, skipping download"
        return 0
    fi
    
    echo "Downloading $file..."
    
    # Download with progress
    if curl --progress-bar -L -o "$file" "$url"; then
        # Verify file exists and is not empty
        if [[ -f "$file" ]] && [[ -s "$file" ]]; then
            success "Download completed successfully"
        else
            error "Downloaded file is empty or corrupted"
            exit 1
        fi
    else
        error "Failed to download $file"
        exit 1
    fi
}

# Detect system type
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            local distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
            local id_like=$(grep "^ID_LIKE=" /etc/os-release | cut -d= -f2 | tr -d '"')
            
            case "$distro" in
                "debian"|"ubuntu"|"linuxmint"|"pop"|"elementary"|"kali")
                    echo "debian"
                    ;;
                "fedora"|"rhel"|"centos"|"almalinux"|"rocky")
                    echo "rpm"
                    ;;
                "opensuse"|"opensuse-tumbleweed"|"opensuse-leap"|"sles")
                    echo "suse"
                    ;;
                "arch"|"manjaro"|"endeavouros")
                    echo "arch"
                    ;;
                *)
                    # Check ID_LIKE for derivatives
                    if [[ "$id_like" == *"debian"* || "$id_like" == *"ubuntu"* ]]; then
                        echo "debian"
                    elif [[ "$id_like" == *"fedora"* || "$id_like" == *"rhel"* || "$id_like" == *"centos"* ]]; then
                        echo "rpm"
                    elif [[ "$id_like" == *"arch"* ]]; then
                        echo "arch"
                    elif [[ "$id_like" == *"suse"* ]]; then
                        echo "suse"
                    else
                        echo "unsupported"
                    fi
                    ;;
            esac
        else
            # Fallback to package manager detection
            if command -v apt-get >/dev/null 2>&1; then
                echo "debian"
            elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                echo "rpm"
            elif command -v pacman >/dev/null 2>&1; then
                echo "arch"
            elif command -v zypper >/dev/null 2>&1; then
                echo "suse"
            else
                echo "unsupported"
            fi
        fi
    else
        error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Install DEB package
install_deb() {
    local version="$1"
    local arch="$2"
    local file="LogParser-${version}-${arch}.deb"
    
    log "Downloading DEB package..."
    show_progress "$file" "$BASE_URL/$file"
    
    log "Installing package..."
    check_sudo
    # Try apt install first (handles dependencies better), then dpkg as fallback
    if command -v apt-get >/dev/null 2>&1; then
        if ! sudo apt-get install -y "./$file"; then
            error "Installation failed"
            exit 1
        fi
    else
        if ! sudo dpkg -i "$file"; then
            warning "dpkg failed, trying to fix dependencies..."
            sudo apt-get install -f -y || { error "Failed to fix dependencies"; exit 1; }
        fi
    fi
    
    success "LogParser installed successfully!"
}

# Install RPM package
install_rpm() {
    local version="$1"
    # RPM usually uses x86_64
    local arch="x86_64" 
    local file="LogParser-${version}-${arch}.rpm"
    
    log "Downloading RPM package..."
    show_progress "$file" "$BASE_URL/$file"
    
    log "Installing package..."
    check_sudo
    
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "./$file"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y --allow-unsigned-rpm "./$file"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "./$file"
    else
        # Fallback to direct rpm install
        sudo rpm -Uvh "./$file"
    fi
    
    success "LogParser installed successfully!"
}

# Install Arch package
install_arch() {
    local version="$1"
    local arch="x86_64"
    local file="LogParser-${version}-${arch}.pkg.tar.zst"
    
    log "Downloading Arch package..."
    show_progress "$file" "$BASE_URL/$file"
    
    log "Installing package..."
    check_sudo
    
    if ! sudo pacman -U --noconfirm "$file"; then
        error "Installation failed"
        exit 1
    fi
    
    success "LogParser installed successfully!"
}

# Main execution
check_network
check_tools

log "Install script v$SCRIPT_VERSION"
log "Installing LogParser v$VERSION"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT
cd "$TEMP_DIR"

BASE_URL="https://github.com/seishio/homebrew-logparser/releases/download/v$VERSION"

SYSTEM_TYPE=$(detect_system)
ARCHITECTURE=$(uname -m)

# Map architecture names if needed
case "$ARCHITECTURE" in
    "x86_64"|"amd64")
        DEB_ARCH="amd64"
        RPM_ARCH="x86_64"
        ARCH_ARCH="x86_64"
        ;;
    *)
        error "Unsupported architecture: $ARCHITECTURE"
        exit 1
        ;;
esac

log "Detected system: $SYSTEM_TYPE ($ARCHITECTURE)"

# Install based on system type
case "$SYSTEM_TYPE" in
    "debian")
        install_deb "$VERSION" "$DEB_ARCH"
        ;;
    "rpm"|"suse")
        install_rpm "$VERSION"
        ;;
    "arch")
        install_arch "$VERSION"
        ;;
    *)
        error "Unsupported Linux distribution. Please install manually using released packages."
        error "Visit: https://github.com/seishio/homebrew-logparser/releases"
        exit 1
        ;;
esac

echo ""
log "Run 'logparser' to start the application."