{ pkgs, ... }:
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]
  );
in
{
  environment.systemPackages = with pkgs; [
    asciinema bat btop gh gitui go slack element-desktop mas rustup starship
    nodejs yarn bun tmux jq ko syft bunyan-rs direnv htop helix zellij lsd
    ripgrep yazi zoxide fzf alacritty wezterm viu buf crane gdk awscli2
    nixpkgs-fmt eza hyperfine claude-code
  ];
}
