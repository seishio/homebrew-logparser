#!/bin/bash
set -euo pipefail

# Script info
SCRIPT_NAME="LogParser Installer"
SCRIPT_VERSION="1.0.0"

# Show help
show_help() {
    echo "Usage: $0 [VERSION] [OPTIONS]"
    echo ""
    echo "Install LogParser on Linux systems"
    echo ""
    echo "Arguments:"
    echo "  VERSION    Specific version to install (e.g., 0.4.30)"
    echo "             If not provided, installs latest version"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -v, --version     Show script version"
    echo "  --version         Show LogParser version (if installed)"
    echo "  uninstall         Uninstall LogParser"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install latest version"
    echo "  $0 0.4.30           # Install specific version"
    echo "  $0 uninstall         # Uninstall LogParser"
    echo ""
    echo "After installation:"
    echo "  logparser            # Run LogParser"
    echo ""
    echo "Desktop Integration:"
    echo "  - Creates desktop file in ~/.local/share/applications/"
    echo "  - Installs icons in ~/.local/share/icons/"
    echo "  - Updates desktop database and icon cache"
    echo "  - Appears in application menu"
}

# Uninstall function
uninstall_logparser() {
    log "Uninstalling LogParser..."
    
    # Remove AppImage
    rm -f "$HOME/.local/bin/logparser"
    
    # Remove desktop integration
    rm -f "$HOME/.local/share/applications/logparser.desktop"
    rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/logparser.png"
    
    # Remove application data and caches
    rm -rf "$HOME/.local/share/LogParser"
    rm -rf "$HOME/.cache/logparser"
    rm -rf "$HOME/.config/logparser"
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    success "LogParser uninstalled successfully"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        echo "$SCRIPT_NAME v$SCRIPT_VERSION"
        exit 0
        ;;
    --version)
        if command -v logparser >/dev/null 2>&1; then
            logparser --version
        else
            error "LogParser is not installed"
            exit 1
        fi
        exit 0
        ;;
    uninstall|--uninstall)
        uninstall_logparser
        exit 0
        ;;
esac

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1" >&2; }
warning() { echo -e "${YELLOW}⚠️${NC} $1" >&2; }

# Get latest version from GitHub API
get_latest_version() {
    local api_url="https://api.github.com/repos/seishio/homebrew-logparser/releases/latest"
    local response
    
    if ! response=$(curl -s "$api_url"); then
        warning "Failed to fetch latest version from GitHub API"
        return 1
    fi
    
    echo "$response" | grep -Po '"tag_name": "v\K[^"]*' || echo ""
}

# Determine version
VERSION="${1:-$(get_latest_version)}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid version: $VERSION"
    exit 1
fi

# Check required dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v sha256sum >/dev/null 2>&1; then
        missing_deps+=("sha256sum")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        log "Please install them and try again"
        exit 1
    fi
}

check_dependencies
log "Installing LogParser v$VERSION"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT
cd "$TEMP_DIR"

BASE_URL="https://github.com/seishio/homebrew-logparser/releases/download/v$VERSION"

# Function to verify checksum
verify_checksum() {
    local file=$1
    local sha_file="${file}.sha256"
    
    log "Downloading checksum..."
    if ! curl -fsSL -o "$sha_file" "$BASE_URL/$sha_file"; then
        error "Failed to download checksum file"
        return 1
    fi
    
    log "Verifying integrity..."
    if ! sha256sum -c "$sha_file"; then
        error "Checksum verification failed"
        return 1
    fi
    success "File verified successfully"
}

# Detect system and install
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check for Debian-based systems
        if command -v dpkg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
            # Check specific distributions
            if [[ -f /etc/debian_version ]]; then
                if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
                    echo "ubuntu"
                elif grep -q "Debian" /etc/os-release 2>/dev/null; then
                    echo "debian"
                elif grep -q "Linux Mint" /etc/os-release 2>/dev/null; then
                    echo "mint"
                elif grep -q "Pop!_OS" /etc/os-release 2>/dev/null; then
                    echo "pop"
                else
                    echo "debian"
                fi
            else
                echo "debian"
            fi
        # Check for Red Hat-based systems
        elif command -v rpm >/dev/null 2>&1; then
            if command -v dnf >/dev/null 2>&1; then
                echo "fedora"
            elif command -v yum >/dev/null 2>&1; then
                if [[ -f /etc/redhat-release ]]; then
                    if grep -q "CentOS" /etc/redhat-release 2>/dev/null; then
                        echo "centos"
                    elif grep -q "Red Hat" /etc/redhat-release 2>/dev/null; then
                        echo "rhel"
                    else
                        echo "rhel"
                    fi
                else
                    echo "rhel"
                fi
            else
                echo "rpm"
            fi
        # Check for Arch-based systems
        elif command -v pacman >/dev/null 2>&1; then
            if grep -q "Manjaro" /etc/os-release 2>/dev/null; then
                echo "manjaro"
            else
                echo "arch"
            fi
        # Check for SUSE systems
        elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/os-release ]] && grep -q "SUSE" /etc/os-release 2>/dev/null; then
            echo "suse"
        # Check for Alpine
        elif command -v apk >/dev/null 2>&1; then
            echo "alpine"
        else
            echo "generic"
        fi
    else
        error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

SYSTEM_TYPE=$(detect_system)
log "Detected system: $SYSTEM_TYPE"

# Detect architecture
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armhf"
            ;;
        *)
            echo "x86_64"  # fallback
            ;;
    esac
}

# Install dependencies function
install_deps() {
    local system_type="$1"
    case "$system_type" in
        "ubuntu"|"debian"|"mint"|"pop")
            sudo apt-get install -y libgtk-3-0 libnotify4 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri
            ;;
        "fedora"|"centos"|"rhel"|"rpm")
            sudo dnf install -y gtk3 libnotify mesa-libEGL libxcb libX11 libXext libXrender mesa-libGL libfuse2 || sudo yum install -y gtk3 libnotify mesa-libEGL libxcb libX11 libXext libXrender mesa-libGL fuse
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm gtk3 libnotify mesa libxcb libx11 libxext libxrender fuse2
            ;;
        "suse")
            sudo zypper install -y gtk3 libnotify Mesa libxcb libX11 libXext libXrender fuse
            ;;
        "alpine")
            sudo apk add --no-cache gtk+3.0 libnotify mesa-egl libxcb libx11 libxext libxrender mesa-gl fuse
            ;;
        *)
            sudo apt-get install -y libfuse2 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libgtk-3-0 libnotify4 libx11-6 libxext6 libxrender1 libgl1-mesa-dri
            ;;
    esac
}

# Ask user about dependencies
ask_install_deps() {
    local system_type="$1"
    echo "Install dependencies? [y/N]: "
    read -p "Choice: " choice
    case $choice in
        [yY]|[yY][eE][sS])
            log "Installing dependencies..."
            if install_deps "$system_type"; then
                success "Dependencies installed!"
            else
                warning "Some deps failed - LogParser may not work correctly"
            fi
            ;;
        *)
            warning "Skipping dependencies - LogParser may not work correctly"
            ;;
    esac
}

ARCHITECTURE=$(detect_architecture)
log "Detected architecture: $ARCHITECTURE"

case "$SYSTEM_TYPE" in
    "ubuntu"|"debian"|"mint"|"pop")
    # Debian-based systems - install DEB for amd64, AppImage for others
    if [[ "$ARCHITECTURE" == "x86_64" || "$ARCHITECTURE" == "amd64" ]]; then
        FILE="LogParser-${VERSION}-amd64.deb"
        log "Downloading DEB package for amd64..."
        curl -fsSL -o "$FILE" "$BASE_URL/$FILE"
        
        verify_checksum "$FILE" || log "Checksum verification skipped"
        
        log "Installing package..."
        
        # Try to install dependencies with graceful fallback
        log "Installing system dependencies..."
        if ! sudo apt-get update && sudo apt-get install -y libgtk-3-0 libnotify4 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri; then
            warning "Could not install all dependencies automatically"
            warning "LogParser will be installed but may not work correctly"
        fi
        
        # Install package with dependency resolution
        if ! sudo dpkg -i "$FILE"; then
            log "Resolving dependencies..."
            if ! sudo apt-get -f install -y; then
                warning "Could not resolve dependencies automatically"
                warning "LogParser will be installed but may not work correctly"
            else
                log "Retrying package installation..."
                sudo dpkg -i "$FILE"
            fi
        fi
        
        if command -v logparser >/dev/null 2>&1; then
            success "LogParser installed successfully!"
            ask_install_deps "$SYSTEM_TYPE"
            log "Run: logparser"
        else
            error "Installation failed"
            exit 1
        fi
    else
        # Use AppImage for non-amd64
        FILE="LogParser-$VERSION-amd64.AppImage"
        log "Downloading AppImage for $ARCHITECTURE..."
        curl -fsSL -o "$FILE" "$BASE_URL/$FILE"
        
        verify_checksum "$FILE" || log "Checksum verification skipped"
        
        chmod +x "$FILE"
        
        # Try to install dependencies with graceful fallback
        log "Installing system dependencies..."
        if ! sudo apt-get update && sudo apt-get install -y libfuse2 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libgtk-3-0 libnotify4 libx11-6 libxext6 libxrender1 libgl1-mesa-dri; then
            warning "Could not install all dependencies automatically"
            warning "LogParser will be installed but may not work correctly"
        fi
        
        # Install AppImage
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
        mv "$FILE" "$INSTALL_DIR/logparser"
        chmod +x "$INSTALL_DIR/logparser"
        
        success "LogParser installed to $INSTALL_DIR/logparser"
        ask_install_deps "$SYSTEM_TYPE"
        log "Run: logparser"
    fi
    ;;
    *)
    # All other systems - install AppImage
    FILE="LogParser-$VERSION-amd64.AppImage"
    log "Downloading AppImage..."
    curl -fsSL -o "$FILE" "$BASE_URL/$FILE"
    
    verify_checksum "$FILE" || log "Checksum verification skipped"
    
    chmod +x "$FILE"
    
    # Try to install dependencies with graceful fallback
    log "Installing system dependencies..."
    if ! install_deps "$SYSTEM_TYPE"; then
        warning "Could not install all dependencies automatically"
        warning "LogParser will be installed but may not work correctly"
    fi
    
    # Install AppImage
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    mv "$FILE" "$INSTALL_DIR/logparser"
    chmod +x "$INSTALL_DIR/logparser"
    
    success "LogParser installed to $INSTALL_DIR/logparser"
    
    # Check PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    
    # Desktop integration
    log "Setting up desktop integration..."
    
    # Create directories
    apps_dir="$HOME/.local/share/applications"
    icons_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
    mkdir -p "$apps_dir" "$icons_dir"
    
    # Create desktop file
    {
      echo "[Desktop Entry]"
      echo "Version=1.0"
      echo "Type=Application"
      echo "Name=LogParser"
      echo "Comment=Log file analyzer"
      echo "Exec=$INSTALL_DIR/logparser"
      echo "Icon=logparser"
      echo "Terminal=false"
      echo "Categories=Utility;"
    } > "$apps_dir/logparser.desktop"
    
    # Download icon from GitHub releases
    log "Downloading icon..."
    if curl -fsSL -o "$icons_dir/logparser.png" "$BASE_URL/icon.png" 2>/dev/null; then
        success "Icon downloaded successfully"
    else
        log "Icon not available, skipping icon installation"
    fi
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$apps_dir" 2>/dev/null || true
    fi
    
    success "Desktop integration complete"
    ask_install_deps "$SYSTEM_TYPE"
    log "Run: logparser"
    ;;
esac
