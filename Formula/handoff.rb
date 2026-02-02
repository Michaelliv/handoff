class Handoff < Formula
  desc "Shared clipboard CLI for humans and AI agents"
  homepage "https://github.com/Michaelliv/handoff"
  url "https://github.com/Michaelliv/handoff/releases/download/v1.0.0/handoff-v1.0.0-universal.tar.gz"
  sha256 "d3c56f79e4e60b8fc13bb0ea82e608c5f788a1c013cff07ad705a7bdb4a0946e"
  license "MIT"
  version "1.0.0"

  depends_on :macos
  depends_on macos: :ventura

  def install
    bin.install "handoff"
  end

  test do
    system "#{bin}/handoff", "--help"
  end
end
