# Placeholder for Homebrew formula
# See issue #5 for implementation details

class Handoff < Formula
  desc "Shared clipboard CLI for humans and AI agents"
  homepage "https://github.com/michaelliv/handoff"
  # url and sha256 to be added when releasing
  license "MIT"

  depends_on :macos

  def install
    bin.install "handoff"
  end

  test do
    system "#{bin}/handoff", "--help"
  end
end
