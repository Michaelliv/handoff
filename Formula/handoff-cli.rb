class HandoffCli < Formula
  desc "Shared clipboard CLI for humans and AI agents"
  homepage "https://github.com/Michaelliv/handoff"
  url "https://github.com/Michaelliv/handoff/releases/download/v1.1.0/handoff-v1.1.0-universal.tar.gz"
  sha256 "d10765aecc211a2e5615c11895a3a525c8bf0b6088f3a39920dc2357df2bfc7b"
  license "MIT"
  version "1.1.0"

  depends_on :macos
  depends_on macos: :ventura

  def install
    bin.install "handoff"
  end

  test do
    system "#{bin}/handoff", "--help"
  end
end
