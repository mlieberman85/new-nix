{ config, pkgs, lib, ... }:
{
  imports = [
    ./nix.nix
    ./system.nix
    ./packages.nix
    ./homebrew.nix
  ];

  system.primaryUser = "mlieberman";

  fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  # NOTE: This stays here (NOT in system.nix). Splitting environment.systemPath
  # into a separate module changes its merge order with nix-darwin's defaults
  # and silently alters $PATH precedence. See specs/.../research.md R9.
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/Users/mlieberman/.deno/bin"
  ];

  system.stateVersion = 4;
  nixpkgs.config.allowUnfree = true;

  # --- Home Manager Configuration ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-bak";
  home-manager.users.mlieberman = { pkgs, lib, ... }: {
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

    programs.nushell.enable = true;

    programs.zsh = {
      enable = true;
      shellAliases = {
        python = "python3";
      };
      # Fixed: initExtra renamed to initContent
      initContent = ''
        source /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration
        PATH=$PATH:/Users/mlieberman/.cargo/bin:/Users/mlieberman/.local/bin/:/Users/mlieberman/go/bin:/Users/mlieberman/.deno/bin
        EDITOR=hx
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        eval "$(starship init zsh)"
      '';
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };

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

    programs.zellij = {
      enable = false;
      enableZshIntegration = false;
    };

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
  };
}
