{ ... }:
{
  # EXPLICITLY disable nix-darwin's nix management so Determinate can do its job.
  # Re-enabling this is a MAJOR constitutional change (Principle IV) — do not flip without amending the constitution first.
  nix.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
