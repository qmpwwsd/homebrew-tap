class Nika < Formula
  desc "Local dashboard of Claude Code agents grouped by project"
  homepage "https://github.com/qmpwwsd/nika"
  url "https://github.com/qmpwwsd/nika/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "b40a25347de400fd6793d922bbe18f8ab21fd984e2d17e7962bb151d10f68d7a"
  license "MIT"

  depends_on "node"

  def install
    libexec.install "bin", "src", "public", "package.json"
    (bin/"nika").write_env_script libexec/"bin/nika", PATH: "#{formula_opt_bin("node")}:$PATH"
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
