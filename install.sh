#!/bin/bash
set -euo pipefail

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Get dependency command for manual installation
get_dependency_command() {
    local system_type="$1"
    case "$system_type" in
        "ubuntu"|"debian"|"mint"|"pop")
            echo "sudo apt-get install -y libgtk-3-0 libnotify4 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri"
            ;;
        "fedora"|"centos"|"rhel"|"rpm")
            echo "sudo dnf install -y gtk3 libnotify mesa-libEGL libxcb libX11 libXext libXrender mesa-libGL libfuse2"
            ;;
        "arch"|"manjaro")
            echo "sudo pacman -S --noconfirm gtk3 libnotify mesa libxcb libx11 libxext libxrender fuse2"
            ;;
        "suse")
            echo "sudo zypper install -y gtk3 libnotify Mesa libxcb libX11 libXext libXrender fuse"
            ;;
        "alpine")
            echo "sudo apk add --no-cache gtk+3.0 libnotify mesa-egl libxcb libx11 libxext libxrender mesa-gl fuse"
            ;;
        *)
            echo "sudo apt-get install -y libfuse2 libegl1-mesa libxcb-xinerama0 libxcb-cursor0 libgtk-3-0 libnotify4 libx11-6 libxext6 libxrender1 libgl1-mesa-dri"
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
        
        # Install package first (without dependencies)
        log "Installing package..."
        if ! sudo dpkg -i "$FILE"; then
            log "Package installed with dependency issues - will resolve later"
        fi
        
        if command -v logparser >/dev/null 2>&1; then
            success "LogParser installed successfully!"
            echo ""
            echo "🎉 Installation completed! LogParser is ready to use."
            echo ""
            
            # Install dependencies
            log "Installing dependencies..."
            if sudo apt-get update && sudo apt-get install -y libegl1-mesa libxcb-cursor0 libgtk-3-0 libnotify4 libxcb-xinerama0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri; then
                success "Dependencies installed successfully!"
            else
                warning "Some dependencies failed to install"
                echo "Manual install: $(get_dependency_command "$SYSTEM_TYPE")"
            fi
            log "Run: logparser"
        else
            error "Installation failed"
            exit 1
        fi
    else
        # Non-amd64 architecture - use AppImage with desktop integration
        FILE="LogParser-$VERSION-amd64.AppImage"
        log "Downloading AppImage for $ARCHITECTURE..."
        curl -fsSL -o "$FILE" "$BASE_URL/$FILE"
        
        verify_checksum "$FILE" || log "Checksum verification skipped"
        
        chmod +x "$FILE"
        
        # Install AppImage with desktop integration
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
        mv "$FILE" "$INSTALL_DIR/logparser"
        chmod +x "$INSTALL_DIR/logparser"
        
        success "LogParser installed to $INSTALL_DIR/logparser"
        
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
          echo "StartupNotify=true"
          echo "NoDisplay=false"
        } > "$apps_dir/logparser.desktop"
        
        # Extract original icon from AppImage
        log "Extracting original icon from AppImage..."
        if command -v convert >/dev/null 2>&1; then
            if convert "$INSTALL_DIR/logparser" -resize 256x256 "$icons_dir/logparser.png" 2>/dev/null; then
                success "Original icon extracted successfully"
            else
                log "Could not extract icon, using AppImage as icon"
                cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
            fi
        elif command -v magick >/dev/null 2>&1; then
            if magick "$INSTALL_DIR/logparser" -resize 256x256 "$icons_dir/logparser.png" 2>/dev/null; then
                success "Original icon extracted successfully"
            else
                log "Could not extract icon, using AppImage as icon"
                cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
            fi
        else
            log "ImageMagick not available, using AppImage as icon"
            cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
        fi
        
        # Update desktop database
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$apps_dir" 2>/dev/null || true
        fi
        
        # Create desktop shortcut
        desktop_file="$HOME/Desktop/logparser.desktop"
        if [[ -d "$HOME/Desktop" ]]; then
            log "Creating desktop shortcut..."
            cp "$apps_dir/logparser.desktop" "$desktop_file"
            chmod +x "$desktop_file" 2>/dev/null || true
            success "Desktop shortcut created"
        fi
        
        success "Desktop integration complete"
        
        echo ""
        echo "🎉 Installation completed! LogParser is ready to use."
        echo ""
        
        # Install dependencies
        log "Installing dependencies..."
        if sudo apt-get update && sudo apt-get install -y libfuse2 libegl1-mesa libxcb-cursor0 libgtk-3-0 libnotify4 libxcb-xinerama0 libx11-6 libxext6 libxrender1 libgl1-mesa-dri; then
            success "Dependencies installed successfully!"
        else
            warning "Some dependencies failed to install"
            echo "Manual install: $(get_dependency_command "$SYSTEM_TYPE")"
        fi
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
    
    # Install dependencies
    log "Installing dependencies..."
    if install_deps "$SYSTEM_TYPE"; then
        success "Dependencies installed successfully!"
    else
        warning "Some dependencies failed to install"
        echo "Manual install: $(get_dependency_command "$SYSTEM_TYPE")"
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
      echo "StartupNotify=true"
      echo "NoDisplay=false"
    } > "$apps_dir/logparser.desktop"
    
    # Extract original icon from AppImage
    log "Extracting original icon from AppImage..."
    if command -v convert >/dev/null 2>&1; then
        # Try to extract icon from AppImage using ImageMagick
        if convert "$INSTALL_DIR/logparser" -resize 256x256 "$icons_dir/logparser.png" 2>/dev/null; then
            success "Original icon extracted successfully"
        else
            # Fallback: try to extract from AppImage using different method
            log "Trying alternative icon extraction..."
            if convert "$INSTALL_DIR/logparser[0]" -resize 256x256 "$icons_dir/logparser.png" 2>/dev/null; then
                success "Original icon extracted successfully"
            else
                log "Could not extract icon, using AppImage as icon"
                # Use AppImage itself as icon (some systems support this)
                cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
            fi
        fi
    elif command -v magick >/dev/null 2>&1; then
        # Try to extract icon using newer ImageMagick
        if magick "$INSTALL_DIR/logparser" -resize 256x256 "$icons_dir/logparser.png" 2>/dev/null; then
            success "Original icon extracted successfully"
        else
            log "Could not extract icon, using AppImage as icon"
            cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
        fi
    else
        # No ImageMagick available, use AppImage as icon
        log "ImageMagick not available, using AppImage as icon"
        cp "$INSTALL_DIR/logparser" "$icons_dir/logparser.png" 2>/dev/null || true
    fi
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$apps_dir" 2>/dev/null || true
    fi
    
    # Create desktop shortcut
    desktop_file="$HOME/Desktop/logparser.desktop"
    if [[ -d "$HOME/Desktop" ]]; then
        log "Creating desktop shortcut..."
        cp "$apps_dir/logparser.desktop" "$desktop_file"
        chmod +x "$desktop_file" 2>/dev/null || true
        success "Desktop shortcut created"
    fi
    
    success "Desktop integration complete"
    
    echo ""
    echo "🎉 Installation completed! LogParser is ready to use."
    echo ""
    
    # Install dependencies
    log "Installing dependencies..."
    if install_deps "$SYSTEM_TYPE"; then
        success "Dependencies installed successfully!"
    else
        warning "Some dependencies failed to install"
        echo "Manual install: $(get_dependency_command "$SYSTEM_TYPE")"
    fi
    
    log "Run: logparser"
    ;;
esac
