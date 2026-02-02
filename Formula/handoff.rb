class Handoff < Formula
  desc "Shared clipboard CLI for humans and AI agents"
  homepage "https://github.com/Michaelliv/shared-clipboard"
  url "https://github.com/Michaelliv/shared-clipboard/releases/download/v#{version}/handoff-#{version}-universal.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  depends_on :macos
  depends_on macos: :ventura

  def install
    bin.install "handoff"
  end

  test do
    system "#{bin}/handoff", "--help"
  end
end
