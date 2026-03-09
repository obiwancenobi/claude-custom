# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class ClaudeCustom < Formula
  desc "Configure Claude Code with custom AI model providers (OpenRouter, Ollama, Cerebras, etc.)"
  homepage "https://github.com/obiwancenobi/claude-custom"
  url "https://raw.githubusercontent.com/obiwancenobi/claude-custom/main/claude-custom"
  sha256 "2b7f79441691e6064a4847fad8ccbb96446ed27823d8b2ea03287a799171737f"
  license "MIT"
  version "1.3.0"

  def install
    bin.install "claude-custom"
  end

  test do
    system "#{bin}/claude-custom", "--version"
  end
end
