class HandoffCli < Formula
  desc "Shared clipboard CLI for humans and AI agents"
  homepage "https://github.com/Michaelliv/handoff"
  url "https://github.com/Michaelliv/handoff/releases/download/v1.1.0/handoff-v1.1.0-universal.tar.gz"
  sha256 "9336337ce0f78762f2f7103cd5c3a44239fe007f72008fdf0a96cf8105224e8f"
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
