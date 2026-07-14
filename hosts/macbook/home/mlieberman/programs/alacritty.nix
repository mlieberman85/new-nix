{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 18;
        normal = { font = "FiraCode Nerd Font Mono"; style = "Regular"; };
        bold = { font = "FiraCode Nerd Font Mono"; style = "Bold"; };
        italic = { font = "FiraCode Nerd Font Mono"; style = "Italic"; };
      };
    };
  };
}
