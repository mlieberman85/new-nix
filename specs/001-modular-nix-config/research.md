# Phase 0 Research: Modular Nix Configuration Layout

**Feature**: 001-modular-nix-config
**Date**: 2026-06-04

This document resolves the open technical questions surfaced while drafting
`plan.md`. Each entry follows the Decision / Rationale / Alternatives format.

---

## R1. How to verify derivation equivalence (SC-004)

**Decision**: Capture
`nix path-info --derivation .#darwinConfigurations.macbook.system` (the
`.drv` path) on the **pre-refactor** baseline and compare against the same
command after each restructure step. Two derivations with the same `.drv`
path are byte-identical; matching is the strongest possible content-neutrality
proof. As a secondary check, compare the realized store path returned by
`darwin-rebuild build --flake .#macbook` (it prints the result symlink).

**Rationale**: Nix `.drv` paths are content-addressed over inputs and build
instructions. If anything materially changes (a package version, an
attribute, a derivation argument), the `.drv` path changes. This is more
sensitive than diffing built outputs and faster than building.

**Alternatives considered**:
- `nix-store --query --hash`: works on realized paths only; requires a build
  first. Equivalent in spirit but slower per iteration.
- `diff` of `nix flake show --json` output: misses things that affect the
  build but not the surface attribute tree.
- Manual eyeballing of `git diff`: useless for catching accidental attrset
  reordering that nix evaluates the same — but also useless for catching
  evaluation drift that nix evaluates differently.

**Operational note**: Run the baseline capture as the FIRST step of
implementation (before any move), and tag the resulting `.drv` in
`research.md` (or a scratch file) so each task can `diff` against it.

---

## R2. Module-split pattern for nix-darwin + home-manager

**Decision**: Use plain `imports = [ ./other.nix ];` lists inside each
module. The host module (`hosts/macbook/default.nix`) imports its peers
(`packages.nix`, `homebrew.nix`, `system.nix`, `nix.nix`) and configures
`home-manager.users.mlieberman.imports = [ ./home/mlieberman ];`. The home
entry (`hosts/macbook/home/mlieberman/default.nix`) imports each per-program
module under `./programs/`.

**Rationale**: This is the native nix-darwin / home-manager idiom — no extra
inputs, no abstraction layer. It composes cleanly with `lib.mkMerge` if two
modules ever need to contribute to the same attribute, and `nix flake check`
catches conflicts. The same pattern appears in nix-darwin's own examples and
in well-maintained personal configs (`mitchellh/nixos-config`,
`Misterio77/nix-config`).

**Alternatives considered**:
- `flake-parts`: would add a flake input (forbidden by Assumptions in spec)
  and pay for itself only with multi-host / multi-system matrices, which is
  not the current scale.
- Custom `options ⇔ config` module schema: explicitly out of scope per the
  spec's Module Style assumption — no payoff for a single-user config.
- `lib.mkMerge`-heavy "feature flag" style: useful when modules toggle each
  other on/off; this refactor has no such conditionality.

---

## R3. Handling the `gdk` let-binding

**Decision**: Move the `gdk` derivation (Google Cloud SDK with
`gke-gcloud-auth-plugin`) into `hosts/macbook/packages.nix` as a `let ... in`
binding scoped to that file. Include it in the same `environment.systemPackages`
list it currently appears in.

```nix
{ pkgs, ... }:
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components; [ gke-gcloud-auth-plugin ]
  );
in
{
  environment.systemPackages = with pkgs; [
    # ... existing list ...
    gdk
  ];
}
```

**Rationale**: The `gdk` binding is package-list-scoped today and has no
consumers outside `environment.systemPackages`. Keeping it co-located with
the list it serves preserves locality (a reader sees the customization at
the use site) and avoids introducing a cross-module attribute pass-through
for a single value.

**Alternatives considered**:
- Top-level `let` shared via overlay or `specialArgs`: over-engineering for
  one binding with one consumer.
- A standalone `hosts/macbook/google-cloud-sdk.nix`: a whole file for one
  derivation tweak is exactly the kind of bloat the refactor is trying to
  avoid.

---

## R4. Where the `home-manager.darwinModules.home-manager` import lives

**Decision**: Keep `home-manager.darwinModules.home-manager` in the
`modules = [ ... ]` list inside the top-level `flake.nix`, alongside
`./hosts/macbook`. The host module sets the home-manager *options*
(`useGlobalPkgs`, `useUserPackages`, `backupFileExtension`,
`users.mlieberman`), but the *module itself* is wired at the flake level
because it is a flake-input concern.

**Rationale**: This keeps the responsibility split clean: `flake.nix` is the
only file that touches `inputs.*`, and the host module is the only file
that touches `home-manager.*` options. A reader looking for "what home
configuration does macbook use?" finds it in `hosts/macbook/default.nix`; a
reader looking for "where does home-manager come from?" finds it in
`flake.nix`. Both questions are answered without grep.

**Alternatives considered**:
- Move `home-manager.darwinModules.home-manager` into the host module via
  `specialArgs.inputs`: works but threads `inputs` through every module
  needlessly when only the top-level wiring needs it today.
- Put all home-manager options in a separate `home-manager.nix` host-level
  module: marginal at best; the options are five lines, and splitting them
  away from the host entry would just create a file with five lines and
  one import, harming locality without aiding discoverability.

---

## R5. Per-program home-manager module shape

**Decision**: Each program module is a function
`{ pkgs, lib, ... }: { programs.<name> = { ... }; }`. No module sets
`home.stateVersion`, `home.packages`, or anything outside its program's
namespace. The entry module (`hosts/macbook/home/mlieberman/default.nix`) is
the *only* place that sets `home.stateVersion` and `home.activation.*`.

**Rationale**: This makes per-program modules trivially copy-pasteable to a
second host without dragging entry-module state, and makes the entry module
the single source of truth for user-level anchors (FR-009 identifiers).

**Alternatives considered**:
- Let any module set `home.activation.*` (or other top-level home options)
  if it needs to: rejected — too easy for activation logic to silently move
  between files in a future edit and break locality.

---

## R6. README content scope

**Decision**: `README.md` documents (a) the directory layout, (b) a
"where do I add X?" table covering system package, brew, cask, home-manager
program, and new host, and (c) a pointer to the constitution for principles
and the existing `quickstart.md` for the canonical build/switch flow. It
does NOT duplicate the build/switch workflow already in the constitution.

**Rationale**: SC-003 measures cold-read time to answer "where do I add a
new home-manager program?" — a short README focused on placement (not
workflow) hits that target. Workflow duplication would create drift between
README and constitution.

**Alternatives considered**:
- Generated docs from module headers: too much machinery for a personal
  config; the layout itself is the doc when each file is named after its
  subject (FR-010).
- Skip the README, rely on directory names: rejected — FR-005 explicitly
  requires a top-level guide for the "what category goes where" decision,
  which directory names alone do not answer (e.g., "is `direnv` a program
  module or a system module?" — the edge cases section in the spec calls
  this out).

---

## R7. Handling the `programs.zsh` split (system-level vs home-manager)

**Decision**: The host-level `system.nix` keeps `programs.zsh.enable = true`
plus `enableSyntaxHighlighting` and `enableFzfHistory` (these are
nix-darwin options affecting the system shell). The per-user home-manager
zsh module (`hosts/macbook/home/mlieberman/programs/zsh.nix`) owns
`programs.zsh.shellAliases` and `programs.zsh.initContent` (these are
home-manager options for the user's zsh config). The README cross-references
this split as the canonical example of the "tooling that crosses Nix layers"
edge case from the spec.

**Rationale**: nix-darwin and home-manager both expose a `programs.zsh`
namespace at different module systems. Today's monolith conflates them in a
single block; splitting per the natural ownership boundary (system shell
behavior vs. user dotfiles) makes both ends locatable by the FR-010 rule
(file name contains "zsh") while respecting the edge case the spec flags.

**Alternatives considered**:
- Put both into one `zsh.nix` under home-manager: rejected — nix-darwin's
  `programs.zsh` options don't exist in home-manager and would silently
  drop.
- Put both into one `zsh.nix` under host modules using `lib.mkMerge` on
  `home-manager.users.mlieberman.programs.zsh`: works but hides user-zsh
  config under the host tree, violating the natural `home/<user>/programs/`
  locality.

---

## R8. Order of host module imports

**Decision**: `hosts/macbook/default.nix` lists imports in this order:
`nix.nix`, `system.nix`, `packages.nix`, `homebrew.nix`. Order is purely
for readability (boundary first, then system, then content); nix module
merging is order-independent for non-overlapping attrsets, and these
modules do not overlap.

**Rationale**: Putting `nix.nix` first surfaces the Determinate boundary at
the top of the host module — the most consequential and most easily
broken constraint is visible first. The rest is grouped from "what kind of
system" (system) to "what's installed" (packages, homebrew).

**Alternatives considered**:
- Alphabetical: optimizes for nothing, hides the boundary.
- Topological by dependency: there is no dependency between these modules
  (each writes disjoint attribute paths).
