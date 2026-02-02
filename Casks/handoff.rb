cask "handoff" do
  version "1.0.0"
  sha256 "d566043fd16dd02f26900fd03813900abdf8be7f7f616af4ccb083223a1a7a33"

  url "https://github.com/Michaelliv/handoff/releases/download/v1.0.0/Handoff-v1.0.0.dmg"
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
