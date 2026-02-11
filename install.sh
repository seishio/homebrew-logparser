#!/bin/bash
set -euo pipefail

SCRIPT_VERSION="0.1.1"

# Colors (with fallback for terminals without color support)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

log() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; }
warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1" >&2; }

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

check_network() {
    if ! timeout 5s curl -sI https://github.com >/dev/null 2>&1; then
        error "No network connectivity"
        exit 1
    fi
}

check_tools
check_network

get_latest_version() {
    local api_url="https://api.github.com/repos/seishio/homebrew-logparser/releases/latest"
    local response

    if ! response=$(timeout 10s curl -s "$api_url" 2>/dev/null); then
        error "Failed to fetch latest version from GitHub"
        error "Usage: curl -fsSL <url> | bash -s -- <version>"
        exit 1
    fi

    local version
    version=$(echo "$response" | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' || echo "")
    if [[ -z "$version" ]]; then
        error "Could not determine latest version from GitHub API"
        error "Usage: curl -fsSL <url> | bash -s -- <version>"
        exit 1
    fi

    echo "$version"
}

VERSION="${1:-$(get_latest_version)}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid version: $VERSION"
    exit 1
fi

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi

    if ! sudo -n true 2>/dev/null; then
        log "sudo access required for package installation"
        # Even when piped, sudo can usually prompt for a password from the TTY
        if ! sudo -v; then
            error "sudo access denied or could not be obtained"
            error "Please run with sudo or ensure your user has sudo privileges"
            exit 1
        fi
    fi
}

show_progress() {
    local file="$1"
    local url="$2"

    echo "Downloading $file..."

    if curl --fail --progress-bar -L -o "$file" "$url"; then
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

verify_checksum() {
    local file="$1"
    local checksum_url="$BASE_URL/${file}.sha256"
    local checksum_file="${file}.sha256"

    if ! curl --fail -sL -o "$checksum_file" "$checksum_url" 2>/dev/null || [[ ! -s "$checksum_file" ]]; then
        warning "Checksum file not available, skipping verification"
        return 0
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        warning "sha256sum not found, skipping verification"
        return 0
    fi

    if sha256sum --check "$checksum_file" >/dev/null 2>&1; then
        success "Checksum verified"
    else
        warning "Checksum mismatch for $file"
    fi
}

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
            # Fallback: detect by available package manager
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

install_deb() {
    local version="$1"
    local arch="$2"
    local file="LogParser-${version}-${arch}.deb"

    log "Downloading DEB package..."
    show_progress "$file" "$BASE_URL/$file"
    verify_checksum "$file"

    log "Installing package..."
    check_sudo
    if command -v apt-get >/dev/null 2>&1; then
        if ! sudo apt-get install -y "./$file"; then
            error "Installation failed"
            exit 1
        fi
    else
        if ! sudo dpkg -i "$file"; then
            error "Installation failed. Install dependencies manually and retry."
            exit 1
        fi
    fi

    success "LogParser installed successfully!"
}

install_rpm() {
    local version="$1"
    local arch="$2"
    local file="LogParser-${version}-${arch}.rpm"

    log "Downloading RPM package..."
    show_progress "$file" "$BASE_URL/$file"
    verify_checksum "$file"

    log "Installing package..."
    check_sudo

    if command -v dnf >/dev/null 2>&1; then
        if ! sudo dnf install -y "./$file"; then
            error "Installation failed"
            exit 1
        fi
    elif command -v zypper >/dev/null 2>&1; then
        if ! sudo zypper install -y --allow-unsigned-rpm "./$file"; then
            error "Installation failed"
            exit 1
        fi
    elif command -v yum >/dev/null 2>&1; then
        if ! sudo yum install -y "./$file"; then
            error "Installation failed"
            exit 1
        fi
    else
        if ! sudo rpm -Uvh "./$file"; then
            error "Installation failed"
            exit 1
        fi
    fi

    success "LogParser installed successfully!"
}

install_arch() {
    local version="$1"
    local arch="$2"
    local file="LogParser-${version}-${arch}.pkg.tar.zst"

    log "Downloading Arch package..."
    show_progress "$file" "$BASE_URL/$file"
    verify_checksum "$file"

    log "Installing package..."
    check_sudo

    if ! sudo pacman -U --noconfirm "$file"; then
        error "Installation failed"
        exit 1
    fi

    success "LogParser installed successfully!"
}

cleanup() { rm -rf "$TEMP_DIR"; }

# --- Main ---

log "Install script v$SCRIPT_VERSION"
log "Installing LogParser v$VERSION"

TEMP_DIR=$(mktemp -d)
trap cleanup EXIT
cd "$TEMP_DIR"

BASE_URL="https://github.com/seishio/homebrew-logparser/releases/download/v$VERSION"

SYSTEM_TYPE=$(detect_system)
ARCHITECTURE=$(uname -m)

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

case "$SYSTEM_TYPE" in
    "debian")
        install_deb "$VERSION" "$DEB_ARCH"
        ;;
    "rpm"|"suse")
        install_rpm "$VERSION" "$RPM_ARCH"
        ;;
    "arch")
        install_arch "$VERSION" "$ARCH_ARCH"
        ;;
    *)
        error "Unsupported Linux distribution. Please install manually using released packages."
        error "Visit: https://github.com/seishio/homebrew-logparser/releases"
        exit 1
        ;;
esac

echo ""
log "Run 'logparser' to start the application."
