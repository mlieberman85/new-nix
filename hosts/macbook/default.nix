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
  home-manager.users.mlieberman = import ./home/mlieberman;
}
