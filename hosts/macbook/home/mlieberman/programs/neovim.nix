{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = true;
    withRuby = false; # Fixed: Disable legacy Ruby default
    plugins = with pkgs.vimPlugins; [
      vim-nix
      gruvbox-community
      nvim-tree-lua
      nvim-web-devicons
      gruvbox-material
      plenary-nvim
      mini-nvim
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
    ];
    # Fixed: extraLuaConfig renamed to initLua
    initLua = ''
      vim.o.termguicolors = true
      vim.cmd('colorscheme gruvbox-material')
      vim.g.gruvbox_material_background = 'hard'
    '';
  };
}
