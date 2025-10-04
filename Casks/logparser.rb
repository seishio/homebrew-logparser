cask "logparser" do
  version "0.4.30"
  sha256 arm:   "fbfaf291397822a3c5abcdb5c4c8ffcca5c5aca3b50982d19dd7eb586236c0bb",
         intel: "1b59874566453d4b6552cfb97fc6e7be3641f3ae58b00dcd8a180b599b86c023"

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
