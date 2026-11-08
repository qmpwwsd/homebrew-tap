class Nika < Formula
  desc "Local dashboard and control panel for Claude Code agents"
  homepage "https://github.com/qmpwwsd/nika"
  url "https://github.com/qmpwwsd/nika/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "56ea8d9603581a4f543673d3dcd7dbbb380b27b2ae48d92103ca24b1f067985a"
  license "MIT"

  depends_on "node"
  on_macos do
    depends_on "rust" => :build
  end

  def install
    # Build the app first: the bundle copies bin, src, public, templates and package.json as resources,
    # and libexec.install below moves them out of the build tree.
    if OS.mac?
      system "cargo", "install", "tauri-cli", "--version", "2.12.4", "--locked", "--root", buildpath/"tools"
      ENV.prepend_path "PATH", buildpath/"tools/bin"
      cd "app/src-tauri" do
        system buildpath/"tools/bin/cargo-tauri", "build", "--bundles", "app"
      end
      prefix.install "app/src-tauri/target/release/bundle/macos/nika.app"
    end

    libexec.install "bin", "src", "public", "templates", "package.json"
    (bin/"nika").write_env_script libexec/"bin/nika", PATH: "#{formula_opt_bin("node")}:$PATH"
  end

  def caveats
    return unless OS.mac?

    <<~EOS
      The desktop app is #{opt_prefix}/nika.app. Open it once so macOS registers it
      (after that `nika` and `nika app` find it):
        open #{opt_prefix}/nika.app
      The read-only browser dashboard still runs with: brew services start nika
    EOS
  end

  service do
    run [opt_bin/"nika", "serve"]
    keep_alive true
    log_path var/"log/nika.log"
    error_log_path var/"log/nika.log"
    environment_variables PATH: std_service_path_env
  end

  test do
    assert_match "nika #{version}", shell_output("#{bin}/nika --version")
    (testpath/"claude/sessions").mkpath
    (testpath/"claude/projects").mkpath
    ENV["CLAUDE_CONFIG_DIR"] = testpath/"claude"
    ENV["NIKA_TMP_ROOT"] = testpath/"tmp"
    assert_match "\"groups\": []", shell_output("#{bin}/nika status --json --since all")
  end
end
