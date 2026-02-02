cask "handoff" do
  version "1.1.0"
  sha256 "236e43831656ed35301eb710022f377c6a33c3a73408bfad33aad913c4b828f8"

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
