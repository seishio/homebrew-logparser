cask "logparser" do
  version "0.4.37"
  sha256 "0009568d277fead4dd9153eb1a1bd653843ebea22a8eb33f5b19fb7e0b2d7ef2"

  url "https://github.com/seishio/homebrew-logparser/releases/download/v#{version}/LogParser-#{version}-macos-arm64.dmg"
  name "LogParser"
  desc "Fast log file analyzer supporting multiple formats"
  homepage "https://github.com/seishio/homebrew-logparser"

  livecheck do
    url "https://github.com/seishio/homebrew-logparser/releases/latest"
    regex(%r{href=.*?/tag/v?(\d+(?:\.\d+)+)["' >]}i)
  end

  depends_on arch: :arm64
  depends_on macos: :big_sur

  app "LogParser.app"

  # Remove quarantine attribute to avoid security warnings
  postflight do
    system_command "xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/LogParser.app"]
  end

  zap trash: [
    "~/Library/Application Support/LogParser",
    "~/Library/Preferences/LogParser",
    "~/Library/Saved Application State/dev.logparser.app.savedState",
  ]
end
