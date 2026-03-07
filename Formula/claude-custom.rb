# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Claudecustom < Formula
  desc "Configure Claude Code with custom AI model providers (OpenRouter, Ollama, Cerebras, etc.)"
  homepage "https://github.com/obiwancenobi/claude-custom"
  url "https://raw.githubusercontent.com/obiwancenobi/claude-custom/main/claude-custom"
  sha256 "893ded288b2282f5d658f31c82a4f000d515bfde209020a6aaff685d8be665d9"
  license "MIT"
  version "1.2.0"

  def install
    bin.install "claude-custom"
  end

  test do
    system "#{bin}/claude-custom", "--version"
  end
end
