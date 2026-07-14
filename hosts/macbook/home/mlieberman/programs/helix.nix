{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        true-color = true;
        lsp.display-messages = true;
      };
    };
    languages = {
      language = [
        { name = "rust"; auto-format = true; }
        {
          name = "nix";
          auto-format = true;
          # Fixed: Use pkgs.nixfmt instead of nixfmt-rfc-style
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
      ];
    };
  };
}
