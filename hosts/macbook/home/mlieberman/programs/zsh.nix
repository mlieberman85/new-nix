{ ... }:
{
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
}
