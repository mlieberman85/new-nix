{ pkgs, lib, ... }:
{
  imports = [
    ./programs/alacritty.nix
    ./programs/nushell.nix
    ./programs/zsh.nix
    ./programs/zoxide.nix
    ./programs/wezterm.nix
    ./programs/zellij.nix
    ./programs/helix.nix
    ./programs/neovim.nix
  ];

  home.stateVersion = "24.11";

  home.activation.installSpecKit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.git}/bin:/opt/homebrew/bin:$PATH"
    if command -v uv >/dev/null 2>&1; then
      if uv tool list 2>/dev/null | grep -q '^specify-cli '; then
        $DRY_RUN_CMD uv tool upgrade specify-cli || true
      else
        $DRY_RUN_CMD uv tool install --from git+https://github.com/github/spec-kit.git specify-cli || true
      fi
    fi
  '';

  home.activation.dockerComposePlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.docker/cli-plugins
    $DRY_RUN_CMD ln -sf /opt/homebrew/opt/docker-compose/bin/docker-compose \
      $HOME/.docker/cli-plugins/docker-compose
  '';
}
