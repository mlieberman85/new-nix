# Implementation Plan: Modular Nix Configuration Layout

**Branch**: `001-modular-nix-config` | **Date**: 2026-06-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-modular-nix-config/spec.md`

## Summary

Refactor the 222-line monolithic `flake.nix` into a `hosts/<hostname>/` module
tree so that routine additions (system package, brew/cask, home-manager program
tweak) touch exactly one file. The refactor is content-neutral: every package,
brew, cask, tap, font, and program setting present today is preserved
byte-for-byte in semantic meaning, verified by an unchanged
`darwin-rebuild build --flake .#macbook` derivation hash (SC-004). No new
flake inputs, no `flake.lock` change, no toggling of `nix.enable`.

## Technical Context

**Language/Version**: Nix (flake-based), targeting `nixpkgs-unstable` channel
pinned in `flake.lock`

**Primary Dependencies**: `nix-darwin` (LnL7), `home-manager` (nix-community).
Both follow `nixpkgs` via `inputs.nixpkgs.follows = "nixpkgs"`. Determinate Nix
installer manages the daemon (`nix.enable = false` in nix-darwin).

**Storage**: N/A — file-based configuration only.

**Testing**:
- `nix flake check` (evaluation correctness)
- `darwin-rebuild build --flake .#macbook` (full build to a derivation)
- Equivalence test (REVISED per research R1, 2026-06-08): a normalized
  JSON snapshot of `darwinConfigurations.macbook.config` (curated to the
  user-facing leaves enumerated in SC-004) MUST diff cleanly between
  pristine HEAD and the post-refactor working tree. The literal `.drv`
  hash is NOT used as an oracle (nix-darwin embeds `_file` paths in
  `options.json`, making any module move fail a strict .drv-hash test
  while remaining functionally identical).

**Target Platform**: `aarch64-darwin` only. Host `macbook`, user `mlieberman`.

**Project Type**: Personal Nix Darwin system configuration (single-user,
single-host today; structure must welcome a second host additively per US3).

**Performance Goals**: Build time of the restructured flake SHOULD be within
±10% of the monolith on cold and warm `nix flake check`. No hard target;
content-neutrality is the load-bearing guarantee, not speed.

**Constraints**:
- Top-level `flake.nix` ≤ 60 lines (SC-006), currently 222.
- Routine additions (package / brew / cask / program) touch ≤ 1 file in ≥ 90%
  of cases (SC-002).
- Identical system derivation before/after (FR-001, SC-004).
- No `flake.lock` modification during this feature (FR-008, Principle II).
- No new flake inputs (Assumptions; no `flake-parts`, no `flake-utils`).
- `nix.enable = false` MUST remain (Principle IV, FR-006).
- All five load-bearing identifiers preserved verbatim: `system.primaryUser`,
  `system.stateVersion = 4`, `home.stateVersion = "24.11"`,
  `nixpkgs.config.allowUnfree = true`, `home.activation.installSpecKit`
  (FR-009).

**Scale/Scope**: ~222 lines split across ~12–15 small modules. Estimated
deliverables: 1 host entry module, 3 host-level modules (packages, homebrew,
system), 1 home entry module, ~8 per-program home-manager modules, 1
top-level `README.md`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against `.specify/memory/constitution.md` v1.0.0:

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Declarative Reproducibility (NON-NEGOTIABLE) | PASS | Pure refactor; no imperative side-channels introduced or removed. Every declarative entry preserved (FR-001, FR-009). |
| II. Pinned & Deliberate Inputs | PASS | `flake.lock` is explicitly out of scope (FR-008). No new inputs (Assumptions). |
| III. Nix First, Homebrew Only Where Necessary | PASS | Existing nix-vs-brew choices preserved unchanged. The new `homebrew.nix` module makes the inventory more reviewable, supporting Principle III's "should be justifiable on review" clause. |
| IV. Determinate-Compatible Daemon Boundary | PASS | `nix.enable = false` and `nix.settings.experimental-features` move into a host-level `system.nix` module verbatim. FR-006 explicitly forbids re-enabling. |
| V. Build Before Switch | PASS | FR-007 requires `nix flake check` + `darwin-rebuild build` to succeed before the feature is complete. SC-004 derivation-hash equivalence is the stronger form of this gate for a refactor. |

**Result**: All five principles PASS with no justified deviations.
Complexity Tracking section below is intentionally empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-modular-nix-config/
├── spec.md              # Already exists (drafted 2026-05-20)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output — module tree + per-module contracts
├── quickstart.md        # Phase 1 output — "where do I add X?" cheat sheet
├── checklists/
│   └── requirements.md  # Already exists (passed 2026-05-20)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

No `contracts/` directory: this feature exposes no external API, CLI, or
service boundary. Per-module interface "contracts" (what attribute paths each
file sets) are captured inline in `data-model.md`.

### Source Code (repository root)

```text
flake.nix                                  # ≤ 60 lines: inputs, outputs, darwinConfigurations wiring only
README.md                                  # NEW: directory layout + where-to-add-what guide (FR-005)
flake.lock                                 # UNCHANGED (FR-008)

hosts/
└── macbook/
    ├── default.nix                        # host entry: imports + system.primaryUser, system.stateVersion, nixpkgs.config.allowUnfree, fonts.packages
    ├── nix.nix                            # nix.enable = false, nix.settings.experimental-features (Principle IV boundary, isolated)
    ├── packages.nix                       # environment.systemPackages (including the gdk let-binding)
    ├── system.nix                         # environment.systemPath, programs.zsh top-level enable, programs.direnv.enable, users.users.mlieberman
    ├── homebrew.nix                       # homebrew.{enable, onActivation, brews, casks, taps}
    └── home/
        └── mlieberman/
            ├── default.nix                # home-manager user entry: imports + home.stateVersion + home.activation.installSpecKit
            └── programs/
                ├── alacritty.nix
                ├── nushell.nix
                ├── zsh.nix                # programs.zsh (home-manager): shellAliases, initContent
                ├── zoxide.nix
                ├── wezterm.nix
                ├── zellij.nix
                ├── helix.nix
                └── neovim.nix
```

**Structure Decision**: `hosts/<hostname>/` tree. The current host lives under
`hosts/macbook/`. A second host (per US3) is added by creating
`hosts/<newhost>/` plus one line under `darwinConfigurations` in `flake.nix`,
modifying zero existing files under `hosts/macbook/`. Each per-program
home-manager module is one file named after the program (FR-010). The
`nix.nix` module isolates the Determinate boundary (Principle IV) so any
future change touching it stands out in `git log`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

(Empty — all principles pass.)
