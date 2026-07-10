cask "logparser" do
  version "0.4.37"
  sha256 "e7d4d38c59ec54bdfb446609da39ee03039c83452c06bb7e5be7adba4ea4dd60"

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
