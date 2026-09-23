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
      PATH=/opt/homebrew/opt/libpq/bin:$PATH:/Users/mlieberman/.cargo/bin:/Users/mlieberman/.local/bin/:/Users/mlieberman/go/bin:/Users/mlieberman/.deno/bin
      EDITOR=hx
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
      eval "$(rbenv init - zsh)"
      eval "$(starship init zsh)"

      # Nag (don't act) when this repo's flake.lock has gone stale.
      if [[ -o interactive && -f $HOME/Projects/new-nix/flake.lock ]]; then
        _nix_age=$(( ($(date +%s) - $(stat -f %m $HOME/Projects/new-nix/flake.lock)) / 86400 ))
        if (( _nix_age > 14 )); then
          print -P "%F{yellow}nix config is ''${_nix_age}d stale — run ~/Projects/new-nix/update.sh%f"
        fi
        unset _nix_age
      fi
    '';
  };
}
