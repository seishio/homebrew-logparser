cask "logparser" do
  version "0.4.30"
  sha256 arm:   "7099295246db872dc83763f4476815214b29bbd2eccb6fb70f8eb8860b87b60e",
         intel: "12f68d5e3c793f221967dda281bfaf87d28488389f757daf945d352c31adfffc"

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
