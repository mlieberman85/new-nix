{ ... }:
{
  # NOTE: environment.systemPath stays in default.nix, NOT here. Moving it
  # into a separate module changes the merge order with nix-darwin's
  # defaults (the user entries end up before or after the nix profile paths
  # depending on priority), silently altering $PATH precedence. See
  # research.md R9.

  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
    enableFzfHistory = true;
  };

  programs.direnv.enable = true;

  users.users.mlieberman = {
    name = "mlieberman";
    home = "/Users/mlieberman";
  };
}
