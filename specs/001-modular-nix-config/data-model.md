# Phase 1 Data Model: Modular Nix Configuration Layout

**Feature**: 001-modular-nix-config
**Date**: 2026-06-04

The "data model" for this feature is the module tree itself: which file owns
which attribute paths in the merged nix-darwin / home-manager configuration.
Each module is treated as an entity with a *contract* (what attribute paths
it sets) and *fields* (the concrete attribute names within those paths).

This document is the single source of truth for the post-refactor layout.
`tasks.md` (Phase 2) will be generated against it.

---

## Entity: Top-level flake (`flake.nix`)

**Owns**:
- `description`
- `inputs.nixpkgs`, `inputs.darwin`, `inputs.home-manager` (with `follows`)
- `outputs` lambda
- `darwinConfigurations."macbook"` = `darwin.lib.darwinSystem { system; modules; }`
- The `modules` list, containing exactly:
  - `home-manager.darwinModules.home-manager`
  - `./hosts/macbook`

**Hard limit**: ≤ 60 lines total (SC-006).

**Does NOT own** (anything that is currently inline must move):
- `environment.systemPackages` (→ `packages.nix`)
- `homebrew.*` (→ `homebrew.nix`)
- `nix.enable`, `nix.settings` (→ `nix.nix`)
- `system.primaryUser`, `system.stateVersion`, `nixpkgs.config.allowUnfree`
  (→ `hosts/macbook/default.nix`)
- `environment.systemPath`, `programs.zsh.enable`,
  `programs.direnv.enable`, `users.users.mlieberman`, `fonts.packages`
  (→ `system.nix` or `default.nix` as noted in each module below)
- `home-manager.useGlobalPkgs`, `home-manager.useUserPackages`,
  `home-manager.backupFileExtension`, `home-manager.users.mlieberman`
  (→ `hosts/macbook/default.nix`)

---

## Entity: Host module (`hosts/macbook/default.nix`)

**Imports**: `./nix.nix`, `./system.nix`, `./packages.nix`, `./homebrew.nix`
(see R8 for order rationale).

**Owns**:
- `system.primaryUser = "mlieberman";`
- `system.stateVersion = 4;`
- `nixpkgs.config.allowUnfree = true;`
- `fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);`
- `environment.systemPath = [ "/opt/homebrew/bin" "/Users/mlieberman/.deno/bin" ];`
  — moved here from system.nix per R9 to preserve `$PATH` merge order.
- `home-manager.useGlobalPkgs = true;`
- `home-manager.useUserPackages = true;`
- `home-manager.backupFileExtension = "hm-bak";`
- `home-manager.users.mlieberman = import ./home/mlieberman;` (function
  signature `{ pkgs, lib, ... }: { imports = [ ./programs/... ]; ... }`).

**Load-bearing identifiers preserved** (FR-009): `system.primaryUser`,
`system.stateVersion`, `nixpkgs.config.allowUnfree`.

---

## Entity: Determinate boundary module (`hosts/macbook/nix.nix`)

**Owns**:
- `nix.enable = false;` (Principle IV; FR-006)
- `nix.settings.experimental-features = [ "nix-command" "flakes" ];`

**Invariant**: this module is the only place `nix.enable` or `nix.settings`
appears in the tree. A second occurrence anywhere is a regression.

---

## Entity: System packages module (`hosts/macbook/packages.nix`)

**Function signature**: `{ pkgs, ... }: { ... }`.

**Owns**:
- `environment.systemPackages` (the entire current list, byte-equivalent set)
- Local `let gdk = pkgs.google-cloud-sdk.withExtraComponents (...);` binding
  used by the list (per R3).

**Current contents** (must be preserved as a set; ordering may be normalized
for readability provided the set is identical):

```
asciinema bat btop gh gitui go slack element-desktop mas rustup starship
nodejs yarn bun tmux jq ko syft bunyan-rs direnv htop helix zellij lsd
ripgrep yazi zoxide fzf alacritty wezterm viu buf crane gdk awscli2
nixpkgs-fmt eza hyperfine claude-code
```

**Validation**: the post-refactor `environment.systemPackages` set MUST be
the same set as the pre-refactor list (no additions, no removals). Compare
via `nix eval .#darwinConfigurations.macbook.config.environment.systemPackages
--apply 'pkgs: map (p: p.name or p.pname or "?") pkgs'` on both sides.

---

## Entity: System module (`hosts/macbook/system.nix`)

**Owns**:
- `programs.zsh = { enable = true; enableSyntaxHighlighting = true; enableFzfHistory = true; };`
  (system-level zsh; user-level zsh lives in `home/mlieberman/programs/zsh.nix` — see R7)
- `programs.direnv.enable = true;`
- `users.users.mlieberman = { name = "mlieberman"; home = "/Users/mlieberman"; };`

**Does NOT own** (REVISED per R9, 2026-06-08):
- `environment.systemPath` lives in `hosts/macbook/default.nix`, NOT here.
  Moving it changes the merge order with nix-darwin's multi-priority
  defaults and silently alters `$PATH` precedence.

---

## Entity: Homebrew module (`hosts/macbook/homebrew.nix`)

**Owns**:
- `homebrew.enable = true;`
- `homebrew.onActivation = { autoUpdate = true; upgrade = true; cleanup = "zap"; };`
- `homebrew.brews` (current list, preserved verbatim)
- `homebrew.casks` (current list, preserved verbatim)
- `homebrew.taps` (current list, preserved verbatim)

**Validation**: the three lists post-refactor MUST be set-equivalent to the
pre-refactor lists. No additions or removals as part of this feature
(Principle III decisions are out of scope for the refactor).

---

## Entity: Home entry module (`hosts/macbook/home/mlieberman/default.nix`)

**Function signature**: `{ pkgs, lib, ... }: { ... }`.

**Imports**: every file under `./programs/` (explicit list, not a directory
glob — Nix evaluates the file list once and surprises from new files in the
directory are bad).

```nix
imports = [
  ./programs/alacritty.nix
  ./programs/nushell.nix
  ./programs/zsh.nix
  ./programs/zoxide.nix
  ./programs/wezterm.nix
  ./programs/zellij.nix
  ./programs/helix.nix
  ./programs/neovim.nix
];
```

**Owns**:
- `home.stateVersion = "24.11";` (load-bearing per FR-009)
- `home.activation.installSpecKit` (verbatim from current flake; load-bearing
  per FR-009)

**Invariant**: no per-program module sets `home.stateVersion` or
`home.activation.*` (per R5).

---

## Entity: Per-program home-manager modules (`hosts/macbook/home/mlieberman/programs/`)

Each module is `{ pkgs, lib, ... }: { programs.<name> = { ... }; }` and
owns exactly its program's namespace.

| File | Owns |
|------|------|
| `alacritty.nix` | `programs.alacritty.{enable, settings.font.{size, normal, bold, italic}}` |
| `nushell.nix` | `programs.nushell.enable` |
| `zsh.nix` | `programs.zsh.{enable, shellAliases.python, initContent}` (user-level — distinct from system-level in `system.nix`, see R7) |
| `zoxide.nix` | `programs.zoxide.{enable, enableBashIntegration, enableZshIntegration, enableNushellIntegration}` |
| `wezterm.nix` | `programs.wezterm.{enable, enableZshIntegration, extraConfig}` |
| `zellij.nix` | `programs.zellij.{enable, enableZshIntegration}` (currently both `false` — preserved) |
| `helix.nix` | `programs.helix.{enable, settings, languages.language[]}` (the `pkgs.nixfmt` interpolation in `formatter.command` is preserved) |
| `neovim.nix` | `programs.neovim.{enable, defaultEditor, viAlias, vimAlias, vimdiffAlias, withPython3, withRuby, plugins, initLua}` |

**FR-010 verification**: every file's basename contains the program name.
A reader looking for "where is helix configured?" finds `helix.nix` by
`fd helix` or visual scan of the `programs/` directory.

---

## State transitions

This refactor has exactly one state transition:

```
S0 (today): monolithic flake.nix, 222 lines, all attributes inline
   │
   │  per-module move (one task per entity above)
   │  each move verified by R1 derivation-hash equivalence
   ▼
S1 (target): modular tree as specified above
            flake.nix ≤ 60 lines
            same .drv path as S0
            same realized system store path as S0
```

There is no intermediate "partially refactored, still builds" guarantee
required of every commit (per spec edge case: intermediate commits may
temporarily fail to build; the *branch final state* must build and produce
the equivalent derivation).
