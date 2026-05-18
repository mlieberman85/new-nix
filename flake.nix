{
  description = "Darwin system flake with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager }:
  let
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations."macbook" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        home-manager.darwinModules.home-manager
        ({ config, pkgs, lib, ... }:
        let
          gdk = pkgs.google-cloud-sdk.withExtraComponents (
            with pkgs.google-cloud-sdk.components; [
              gke-gcloud-auth-plugin
            ]
          );
        in
        {
          # EXPLICITLY disable nix-darwin's nix management so Determinate can do its job
          nix.enable = false;
          
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          system.primaryUser = "mlieberman";

          environment.systemPackages = with pkgs; [
            asciinema bat btop gh gitui go slack element-desktop mas rustup starship
            nodejs yarn tmux jq ko syft bunyan-rs direnv htop helix zellij lsd
            ripgrep yazi zoxide fzf alacritty wezterm viu buf crane gdk awscli2
            nixpkgs-fmt eza hyperfine claude-code
           ];

          fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

          environment.systemPath = [
            "/opt/homebrew/bin"
            "/Users/mlieberman/.deno/bin"
          ];

          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";
            };
            brews = [
              "dust" "nx" "nono" "yabai" "skhd" "openssl" "llvm" "surreal" "colima"
              "protobuf" "gleam" "pkg-config" "cairo" "pango" "ttyd" "minder" "yq"
              "grpcurl" "cmake" "duckdb" "atlassian-plugin-sdk" "osv-scanner" "freerdp"
              "deno" "poppler" "wtfutil" "aichat" "task" "taskwarrior-tui" "jj" "aider"
              "ollama" "binsider" "trufflehog" "zola" "jjui" "act" "docker"
              "golangci-lint" "uv" "snyk" "valkey" "pnpm" "binaryen" "googleworkspace-cli"
            ];
            casks = [
              "visual-studio-code" "1password-cli" "font-hack-nerd-font" "warp" "alfred"
              "bruno" "mockoon" "ghostty" "zed"
            ];
            taps = [
              "koekeishiya/formulae" "surrealdb/tap" "stacklok/tap"
              "atlassian/tap" "defenseunicorns/tap" "PeonPing/tap"
            ];
          };

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

          system.stateVersion = 4;
          nixpkgs.config.allowUnfree = true;

          # --- Home Manager Configuration ---
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
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
        })
      ];
    };
  };
}
