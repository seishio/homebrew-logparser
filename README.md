# LogParser Homebrew Tap

[![Version](https://img.shields.io/github/v/release/seishio/homebrew-logparser?label=version&color=brightgreen)](https://github.com/seishio/homebrew-logparser/releases)

LogParser is a fast log file analyzer supporting multiple formats. This repository provides the Homebrew Cask for macOS, a native installer for Linux, and Windows builds.

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

```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```
The script automatically detects your distribution (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE) and installs the appropriate package.

### Windows
Download the latest `.exe` from the [Releases](https://github.com/seishio/homebrew-logparser/releases) page.

---

<details>
<summary><b>Updating</b></summary>

**macOS:**
```bash
brew upgrade --cask logparser
```

**Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```
</details>

<details>
<summary><b>Uninstalling</b></summary>

**macOS:**
```bash
brew uninstall --cask logparser
```

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
<summary><b>Troubleshooting</b></summary>

#### Complete Removal (macOS)
If something went wrong, remove the app along with all its data:
```bash
brew uninstall --zap --cask logparser
brew untap seishio/logparser
```

#### SHA-256 Mismatch Error (macOS)
```bash
brew cleanup --prune=all
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser
```

#### Dependency Issues (Linux DEB)
```bash
sudo apt-get install -f
```

#### Permission Denied (Linux)
```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | sudo bash
```
</details>
