{ ... }:
{
  # EXPLICITLY disable nix-darwin's nix management so Determinate can do its job.
  # Re-enabling this is a MAJOR constitutional change (Principle IV) — do not flip without amending the constitution first.
  nix.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.substituters = [ "https://claude-code.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
  ];
}
