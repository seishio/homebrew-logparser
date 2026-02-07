cask "logparser" do
  version "0.4.32"
  sha256 arm:   "2903d717477572ebd0d33d348d4f03ef61c69e05346ea9720dcb844a693078b7",
         intel: "b6e330db3a95a1f9348c842346002ca32c8e32ec3817e940d89c57c4d20bc1f1"

  url "https://github.com/seishio/homebrew-logparser/releases/download/v#{version}/LogParser-#{version}-macos-#{Hardware::CPU.arm? ? "arm64" : "intel"}.dmg"
  name "LogParser"
  desc "LogParser is a fast log file analyzer supporting multiple formats."
  homepage "https://github.com/seishio/homebrew-logparser"
  
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
