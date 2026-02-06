cask "logparser" do
  version "0.4.32"
  sha256 arm:   "1437d47ca5763a311617b3b89f8d02c95ed8ce54026eb5b133b674ab4dc0d286",
         intel: ""

  url "https://github.com/seishio/homebrew-logparser/releases/download/v#{version}/LogParser-#{version}-macos-#{Hardware::CPU.arm? ? "arm64" : "intel"}.dmg"
  name "LogParser"
  desc "LogParser is a fast log file analyzer supporting multiple formats."
  homepage "https://github.com/seishio/LogParser"
  
  depends_on macos: ">= :catalina"
  
  conflicts_with cask: [
    "logparser-beta",
    "logparser-dev",
  ]

  livecheck do
    url "https://github.com/seishio/homebrew-logparser/releases/latest"
    regex(%r{href=.*?/tag/v?(\d+(?:\.\d+)+)["' >]}i)
  end

  app "LogParser.app"

  # Remove quarantine attribute to avoid security warnings
  postflight do
    system_command "xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/LogParser.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.logparser.*",
    "~/Library/Application Support/LogParser",
    "~/Library/Caches/dev.logparser",
    "~/Library/Logs/LogParser",
    "~/Library/Saved Application State/dev.logparser.savedState",
  ]
end
