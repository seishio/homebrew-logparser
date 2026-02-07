cask "logparser" do
  version "0.4.32"
  sha256 arm:   "2dd6c3a679d0afdbb22111b802d75927434c931e68ae14ff5011964d14d66b2b",
         intel: "5613803c60b54c515194922af71b8f8d94d6d0cd84743eb75ca6f8e29f795c3e"

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
