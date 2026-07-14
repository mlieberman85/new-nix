{ ... }:
{
  nix-homebrew = {
    enable = true;
    user = "mlieberman";
    autoMigrate = true;
    trust.taps = [
      "koekeishiya/formulae"
      "surrealdb/tap"
      "stacklok/tap"
      "defenseunicorns/tap"
      "PeonPing/tap"
      "snyk/tap"
      "minio/stable"
      "nats-io/nats-tools"
    ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
      # Homebrew 4.7+ requires --force/--force-cleanup/$HOMEBREW_ASK whenever
      # `brew bundle install --cleanup` is invoked. nix-darwin's homebrew module
      # doesn't add the flag automatically, so pass it via extraFlags.
      extraFlags = [ "--force-cleanup" ];
    };
    brews = [
      "dust"
      "nx"
      "nono"
      "openssl"
      "llvm"
      "surreal"
      "colima"
      "protobuf"
      "gleam"
      "pkg-config"
      "cairo"
      "pango"
      "ttyd"
      "minder"
      "yq"
      "grpcurl"
      "cmake"
      "duckdb"
      "osv-scanner"
      "freerdp"
      "deno"
      "poppler"
      "wtfutil"
      "aichat"
      "task"
      "taskwarrior-tui"
      "jj"
      "aider"
      "ollama"
      "binsider"
      "trufflehog"
      "zola"
      "jjui"
      "act"
      "docker"
      "docker-compose"
      "cosign"
      "golangci-lint"
      "uv"
      "snyk"
      "valkey"
      "pnpm"
      "binaryen"
      "googleworkspace-cli"
      "rbenv"
      "ruby-build"
      "minio/stable/mc"
      "nats-io/nats-tools/nats"
      "libpq"
    ];
    casks = [
      "visual-studio-code"
      "1password-cli"
      "font-hack-nerd-font"
      "warp"
      "alfred"
      "bruno"
      "mockoon"
      "ghostty"
      "zed"
    ];
    taps = [
      "koekeishiya/formulae"
      "surrealdb/tap"
      "stacklok/tap"
      "defenseunicorns/tap"
      "PeonPing/tap"
      "snyk/tap"
      "minio/stable"
      "nats-io/nats-tools"
    ];
  };
}
