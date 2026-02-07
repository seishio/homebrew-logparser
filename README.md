# LogParser Homebrew Tap

[![Version](https://img.shields.io/github/v/release/seishio/homebrew-logparser?label=version&color=brightgreen)](https://github.com/seishio/homebrew-logparser/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](#license)

This tap provides the LogParser application via Homebrew Cask for macOS and a native installer for Linux.

## About LogParser

LogParser is a fast log file analyzer supporting multiple formats. It provides filtering, highlighting, and export features for efficient log investigation.

## Installation

### macOS
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install LogParser
brew tap seishio/logparser
brew install --cask logparser
```

### Linux (DEB, RPM, Arch)
**Requirements:** `curl`, `sudo`

**Install (auto-detect distribution):**
```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```
*The script automatically detects your distribution (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE) and installs the appropriate package.*

---

<details>
<summary><b>🔄 Updating & Reinstalling</b></summary>

### Update
```bash
# macOS
brew upgrade --cask logparser

# Linux
# Run the install script again to update to the latest version
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```

### Reinstall (macOS)
```bash
# Standard reinstall
brew reinstall --cask logparser

# Complete reinstall (with data cleanup)
brew cleanup && brew uninstall --cask logparser
rm -rf ~/Library/Application\ Support/LogParser ~/Library/Preferences/com.logparser.*
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser
```

### Complete Reset (macOS)
```bash
# Nuclear option - reset everything including Homebrew
brew uninstall --cask logparser
rm -rf ~/Library/Application\ Support/LogParser ~/Library/Preferences/com.logparser.*
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap seishio/logparser
brew install --cask logparser
```
</details>

<details>
<summary><b>🗑️ Uninstalling</b></summary>

### macOS
```bash
brew uninstall --cask logparser
```

### Linux
Use your package manager to remove LogParser:

**Debian/Ubuntu:**
```bash
sudo apt-get remove logparser
```

**Fedora/RHEL/CentOS:**
```bash
sudo dnf remove logparser
```

**Arch Linux:**
```bash
sudo pacman -R logparser
```

**openSUSE:**
```bash
sudo zypper remove logparser
```
</details>

<details>
<summary><b>🛠️ Troubleshooting</b></summary>

#### SHA-256 Mismatch Error (macOS)
If you get a checksum mismatch error, clean your Homebrew cache and retry:
```bash
brew cleanup --prune=all
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser
```
</details>

## License

### Homebrew Tap
This Homebrew tap is provided under the MIT License.

### LogParser Application
**Non-Commercial License** - This software is provided for personal use only. Commercial use, modification, and redistribution are strictly prohibited without explicit written permission.
