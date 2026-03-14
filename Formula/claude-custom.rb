# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula

class ClaudeCustom < Formula
  desc "Configure Claude Code with custom AI model providers (OpenRouter, Ollama, Cerebras, etc.)"
  homepage "https://github.com/obiwancenobi/claude-custom"
  url "https://github.com/obiwancenobi/claude-custom/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "0e04ae270e0a9e95d88fdc4a6519ec2557f5e8b7491bd837a63d33b05e72d3d7"  # Update after tagging: curl -sSL <url> | shasum -a 256
  license "MIT"
  version "1.4.2"

  def install
    bin.install "claude-custom"
    bin.install "functions"
  end

  test do
    system "#{bin}/claude-custom", "--version"
  end
end
