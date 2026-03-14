# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula

class ClaudeCustom < Formula
  desc "Configure Claude Code with custom AI model providers (OpenRouter, Ollama, Cerebras, etc.)"
  homepage "https://github.com/obiwancenobi/claude-custom"
  url "https://github.com/obiwancenobi/claude-custom/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "e83399b53a0f89b48abb90de6b3d19090e8b99eec55344cf633d9a9acaa38d88"  # Update after tagging: curl -sSL <url> | shasum -a 256
  license "MIT"
  version "1.4.1"

  def install
    bin.install "claude-custom"
    bin.install "functions"
  end

  test do
    system "#{bin}/claude-custom", "--version"
  end
end
