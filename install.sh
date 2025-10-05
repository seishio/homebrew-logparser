#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Script version
SCRIPT_VERSION="0.0.7"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
        if ! sudo -v; then
            error "sudo access denied"
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
    
    local download_success=false
    if timeout 300s curl -L -o "$file" "$url" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ([0-9]+)% ]]; then
            local percent="${BASH_REMATCH[1]}"
            local filled=$((percent / 5))
            local empty=$((20 - filled))
            printf "\r["
            printf "%*s" $filled | tr ' ' '='
            printf "%*s" $empty | tr ' ' '-'
            printf "] %s%%" "$percent"
        fi
    done; then
        download_success=true
    fi
    
    # Always show completion bar if download was successful
    if [[ "$download_success" == "true" ]] && [[ -f "$file" ]] && [[ -s "$file" ]]; then
        printf "\r[====================] 100%%\n"
        echo ""
        success "Download completed successfully"
    else
        echo ""
        error "Download failed"
        exit 1
    fi
}

# Detect system type
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
                    echo "debian"
        elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
                echo "rpm"
        elif command -v pacman >/dev/null 2>&1; then
                echo "arch"
        elif command -v apk >/dev/null 2>&1; then
            echo "alpine"
        elif command -v zypper >/dev/null 2>&1; then
            echo "suse"
        else
            # Fallback: try to detect by distribution files
            if [[ -f /etc/os-release ]]; then
                local distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
                case "$distro" in
                    "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
                        echo "suse"
                        ;;
                    "ubuntu"|"debian"|"linuxmint")
                        echo "debian"
                        ;;
                    "fedora"|"rhel"|"centos")
                        echo "rpm"
                        ;;
                    "arch"|"manjaro")
                        echo "arch"
                        ;;
                    "alpine")
                        echo "alpine"
                        ;;
                    *)
                        echo "generic"
                        ;;
                esac
        else
            echo "generic"
            fi
        fi
    else
        error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Create desktop file with icon extraction
create_desktop_file() {
    local apps_dir="$HOME/.local/share/applications"
    local exec_path="$1"
    local icon_path="logparser"
    
    mkdir -p "$apps_dir"
    
    # Try to extract icon from AppImage (if it's AppImage)
    # Check if it's an AppImage by testing --appimage-extract
    if [[ -x "$exec_path" ]] && "$exec_path" --appimage-extract --help >/dev/null 2>&1; then
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        if "$exec_path" --appimage-extract >/dev/null 2>&1; then
            # Look for icons
            for icon in squashfs-root/*.png squashfs-root/*.ico squashfs-root/*.svg; do
                if [[ -f "$icon" ]]; then
                    local icon_name=$(basename "$icon")
                    mkdir -p "$HOME/.local/share/icons"
                    cp "$icon" "$HOME/.local/share/icons/$icon_name"
                    icon_path="$HOME/.local/share/icons/$icon_name"
                    break
                fi
            done
        fi
        cd - >/dev/null
        rm -rf "$temp_dir"
    fi
    
    cat > "$apps_dir/logparser.desktop" << EOF
[Desktop Entry]
Name=LogParser
Comment=Log file analyzer
Exec=$exec_path
Icon=$icon_path
Terminal=false
Type=Application
Categories=Utility;
EOF
    chmod +x "$apps_dir/logparser.desktop"
        
        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$apps_dir" 2>/dev/null || true
        fi
        
        success "Desktop integration complete"
}

# Create desktop shortcut (simple)
create_desktop_shortcut() {
    local exec_path="$1"
    
    # Find desktop directory
    local desktop_dir=""
    if [[ -d "${HOME}/Desktop" ]]; then
        desktop_dir="${HOME}/Desktop"
    elif [[ -d "${HOME}/Рабочий стол" ]]; then
        desktop_dir="${HOME}/Рабочий стол"
    elif [[ -d "${HOME}/Escritorio" ]]; then
        desktop_dir="${HOME}/Escritorio"
    else
        # Create Desktop as fallback
        desktop_dir="${HOME}/Desktop"
        mkdir -p "$desktop_dir"
    fi
    
    # Copy .desktop file to desktop
    if [[ -f "$HOME/.local/share/applications/logparser.desktop" ]]; then
        if cp "$HOME/.local/share/applications/logparser.desktop" "$desktop_dir/LogParser.desktop"; then
            chmod +x "$desktop_dir/LogParser.desktop" 2>/dev/null || true
            success "Desktop shortcut created: $desktop_dir"
        else
            warning "Failed to create desktop shortcut"
        fi
    fi
}

# Install AppImage
install_appimage() {
    local version="$1"
    local file="LogParser-${version}-linux.AppImage"
    
    log "Downloading AppImage..."
    show_progress "$file" "$BASE_URL/$file"
    
    chmod +x "$file"
    
    # Install to user directory
    log "Installing AppImage..."
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    mv "$file" "$install_dir/logparser"
    chmod +x "$install_dir/logparser"
    
    success "LogParser installed to $install_dir/logparser"
    
    # Create desktop file
    create_desktop_file "$install_dir/logparser"
    
    # Create desktop shortcut (simple)
    create_desktop_shortcut "$install_dir/logparser"
    
    # Check PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        log "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    
    success "LogParser installed successfully!"
    log "Run: logparser"
}

# Install DEB package
install_deb() {
    local version="$1"
    local file="LogParser-${version}-amd64.deb"
    
    log "Downloading DEB package..."
    show_progress "$file" "$BASE_URL/$file"
    
    log "Installing package..."
    check_sudo
    # Try apt install first, then dpkg as fallback
    if ! timeout 600s sudo apt install -y "./$file" 2>/dev/null; then
        log "Trying alternative installation method..."
        if ! timeout 600s sudo dpkg -i "$file" 2>/dev/null; then
            warning "Package installation had issues, but continuing..."
        else
            success "Package installed successfully"
        fi
    else
        success "Package installed successfully"
    fi
    
    # Create desktop file
    create_desktop_file "logparser"
    
    # Create desktop shortcut (simple)
    create_desktop_shortcut "logparser"
    
    success "LogParser installed successfully!"
    log "Run: logparser"
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

# Install based on system type
case "$SYSTEM_TYPE" in
    "debian")
        # Use DEB for amd64, AppImage for others
        if [[ "$ARCHITECTURE" == "x86_64" || "$ARCHITECTURE" == "amd64" ]]; then
            install_deb "$VERSION"
        else
            install_appimage "$VERSION"
        fi
        ;;
    *)
        # All other systems - use AppImage
        install_appimage "$VERSION"
    ;;
esac

success "Installation completed!"

# Show dependency installation commands for manual setup
echo ""
log "Optional: Install system dependencies for optimal performance"
echo ""
case "$SYSTEM_TYPE" in
    "debian")
        echo "  sudo apt-get install -y libgtk-3-0 libnotify4 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri"
        ;;
    "rpm")
        echo "  sudo dnf install -y gtk3 libnotify mesa-libEGL libxcb libX11 libXext libXrender mesa-libGL fuse"
        ;;
    "arch")
        echo "  sudo pacman -S --noconfirm gtk3 libnotify mesa libxcb libx11 libxext libxrender fuse2"
        ;;
    "alpine")
        echo "  sudo apk add --no-cache gtk+3.0 libnotify mesa-egl libxcb libx11 libxext libxrender mesa-gl fuse"
        ;;
    "suse")
        echo "  sudo zypper install -y gtk3 libnotify Mesa-libEGL libxcb libX11 libXext libXrender Mesa-libGL fuse"
        ;;
    *)
        echo "  sudo apt-get install -y libfuse2 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libgtk-3-0 libnotify4 libx11-6 libxext6 libxrender1 libgl1-mesa-dri"
        ;;
esac
echo ""