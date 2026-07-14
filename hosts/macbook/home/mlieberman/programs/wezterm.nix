{ ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      return {
        font = wezterm.font 'FiraCode Nerd Font Mono',
        font_size = 16.0,
        color_scheme = "Tomorrow Night",
        front_end = "WebGpu"
      }
    '';
  };
}
