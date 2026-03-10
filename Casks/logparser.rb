cask "logparser" do
  version "0.4.35"
  sha256 arm:   "cc65cf115746f4c52b048879c803c63bca82c4b1ef06791d04f1d442dfba9d00",
         intel: "726f10e2fd41109d351ab26cef72f9f17945e2633d8e9f7d3576519276715ad7"

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
    "~/Library/Preferences/LogParser",
    "~/Library/Application Support/LogParser",
    "~/Library/Saved Application State/dev.logparser.app.savedState",
  ]
end
