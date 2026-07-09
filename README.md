# LogParser Homebrew Tap

[![Version](https://img.shields.io/github/v/release/seishio/homebrew-logparser?label=version&color=brightgreen)](https://github.com/seishio/homebrew-logparser/releases)

LogParser is a fast log file analyzer supporting multiple formats. This repository provides the Homebrew Cask for macOS (Apple Silicon), a native installer for Linux, and Windows builds.

## Installation

### macOS (Apple Silicon)
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install LogParser
brew install --cask seishio/logparser/logparser
```

<details>
<summary>Alternative: add the tap first</summary>

```bash
brew tap seishio/logparser
brew trust --cask seishio/logparser/logparser
brew install --cask logparser
```

Since Homebrew 6, third-party taps are untrusted by default. The fully-qualified
`brew install --cask seishio/logparser/logparser` command handles trust automatically;
with the two-step form you may need `brew trust` as shown above.
</details>

### Linux (DEB, RPM)
**Requirements:** `curl`, `sudo`

```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```
The script automatically detects your distribution (Debian/Ubuntu, Fedora/RHEL, openSUSE) and installs the appropriate package.

### Windows
Download the latest `.exe` from the [Releases](https://github.com/seishio/homebrew-logparser/releases) page.

---

<details>
<summary><b>Updating</b></summary>

**macOS:**
```bash
brew update && brew upgrade --cask logparser
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

**openSUSE:**
```bash
sudo zypper remove logparser
```
</details>

<details>
<summary><b>Troubleshooting</b></summary>

#### Untrusted Tap Error (macOS)
Homebrew 6 requires third-party taps to be trusted:
```bash
brew trust --cask seishio/logparser/logparser
brew install --cask logparser
```

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
brew install --cask seishio/logparser/logparser
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
