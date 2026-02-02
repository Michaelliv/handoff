# Placeholder for Homebrew formula
# See issue #5 for implementation details

class Clip < Formula
  desc "CLI tool for managing shared clipboard content"
  homepage "https://github.com/michaelliv/handoff"
  # url and sha256 to be added when releasing
  license "MIT"

  depends_on :macos

  def install
    bin.install "clip"
  end

  test do
    system "#{bin}/clip", "--help"
  end
end
