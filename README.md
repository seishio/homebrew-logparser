# LogParser Homebrew Tap

[![Version](https://img.shields.io/badge/Version-0.4.30-brightgreen.svg)](https://github.com/seishio/homebrew-logparser/releases)

This tap provides the LogParser application via Homebrew Cask.

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

### Linux (DEB, AppImage)

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```

## Updating & Reinstalling

### Update
```bash
# macOS
brew upgrade --cask logparser

# Linux (same as installation)
curl -fsSL https://raw.githubusercontent.com/seishio/homebrew-logparser/main/install.sh | bash
```

### Force Reinstall
```bash
# Force reinstall
brew reinstall --cask logparser
```

### Reinstall
```bash
# Standard reinstall
brew cleanup && brew uninstall --cask logparser
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser

# Complete reinstall (with data cleanup)
brew cleanup && brew uninstall --cask logparser
rm -rf ~/Library/Application\ Support/LogParser ~/Library/Preferences/com.logparser.*
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser
```

### Complete Reset
```bash
# Nuclear option - reset everything
brew uninstall --cask logparser
rm -rf ~/Library/Application\ Support/LogParser ~/Library/Preferences/com.logparser.*
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap seishio/logparser
brew install --cask logparser
```

### Troubleshooting

#### SHA-256 Mismatch Error
```bash
# Clean cache and reinstall tap
brew cleanup --prune=all
brew untap seishio/logparser
brew tap seishio/logparser
brew install --cask logparser
```

## License

### Homebrew Tap

This Homebrew tap is provided under the MIT License.

### LogParser Application

**Non-Commercial License** - This software is provided for personal use only. Commercial use, modification, and redistribution are strictly prohibited without explicit written permission.
