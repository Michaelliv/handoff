cask "handoff" do
  version "1.1.0"
  sha256 "ae88f8c63aeaa94c6f966090f30e4118c3ad95055e3fcf6dd9ab3284abfc6c32"

  url "https://github.com/Michaelliv/handoff/releases/download/v1.1.0/Handoff-v1.1.0.dmg"
  name "Handoff"
  desc "Menu bar clipboard manager for humans and AI agents"
  homepage "https://github.com/Michaelliv/handoff"

  depends_on macos: ">= :ventura"

  app "Handoff.app"

  zap trash: [
    "~/.handoff",
    "~/Library/Preferences/com.handoff.plist",
  ]
end
