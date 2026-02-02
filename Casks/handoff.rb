cask "handoff" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/Michaelliv/handoff/releases/download/v#{version}/SharedClipboard-#{version}.dmg"
  name "Shared Clipboard"
  desc "Menu bar clipboard manager for humans and AI agents"
  homepage "https://github.com/Michaelliv/handoff"

  depends_on macos: ">= :ventura"

  app "SharedClipboard.app"

  zap trash: [
    "~/.handoff",
    "~/Library/Preferences/com.michaelliv.SharedClipboard.plist",
  ]
end
