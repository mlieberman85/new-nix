# Quickstart: Working with the Modular Layout

**Feature**: 001-modular-nix-config
**Audience**: Future-me, six months from now, opening this repo cold.

This is the cheat sheet the post-refactor `README.md` is generated against.
It answers exactly one question per row: *"where do I edit to do X?"*

---

## "Where do I add a..."

| I want to add... | Edit this file | Example entry |
|---|---|---|
| A new CLI tool from nixpkgs | `hosts/macbook/packages.nix` | append to `environment.systemPackages` list |
| A Homebrew brew | `hosts/macbook/homebrew.nix` | append to `homebrew.brews` |
| A Homebrew cask | `hosts/macbook/homebrew.nix` | append to `homebrew.casks` |
| A Homebrew tap | `hosts/macbook/homebrew.nix` | append to `homebrew.taps` (only if a brew/cask above needs it — Principle III) |
| A new home-manager program | `hosts/macbook/home/mlieberman/programs/<name>.nix` (new file) + add to `imports` in `home/mlieberman/default.nix` | `{ ... }: { programs.<name>.enable = true; }` |
| A tweak to an existing program | `hosts/macbook/home/mlieberman/programs/<name>.nix` | edit in place |
| A second host | `hosts/<newhost>/` (new tree) + new entry in `flake.nix` `darwinConfigurations` | mirror `hosts/macbook/` layout; do not touch `hosts/macbook/` |
| A system-level nix-darwin option | `hosts/macbook/system.nix` (or `default.nix` for system identity options like `primaryUser`, `stateVersion`) | by attribute path |
| A new `$PATH` entry (`environment.systemPath`) | `hosts/macbook/default.nix` — NOT system.nix | append to the list. See research.md R9 for why this option lives in default.nix. |
| A change to the Determinate boundary | `hosts/macbook/nix.nix` | see Principle IV before touching — `nix.enable` MUST stay `false` |
| A new flake input | `flake.nix` | also requires a constitutional sanity check (Principle II) |

---

## Build & switch

The full workflow is in `.specify/memory/constitution.md` (Principle V and
the Development Workflow section). The short form:

```sh
nixpkgs-fmt flake.nix
darwin-rebuild build --flake .#macbook   # MUST succeed first
darwin-rebuild switch --flake .#macbook
# verify in a fresh shell; if broken: darwin-rebuild --rollback
```

---

## Refactor acceptance check (run once, at end of this feature)

```sh
# Pre-refactor (run on a pristine HEAD via temporary stash):
git stash -u
nix eval --json .#darwinConfigurations.macbook.config \
  --apply "$(cat /tmp/oracle.nix)" 2>/dev/null \
  | jq -S . > /tmp/snapshot.pristine.json
git stash pop

# Post-refactor:
nix eval --json .#darwinConfigurations.macbook.config \
  --apply "$(cat /tmp/oracle.nix)" 2>/dev/null \
  | jq -S . > /tmp/snapshot.final.json

diff /tmp/snapshot.pristine.json /tmp/snapshot.final.json   # MUST be empty modulo pre-existing uncommitted edits (SC-004)
wc -l flake.nix                                              # MUST be ≤ 60 (SC-006)
```

If the diff has *unexpected* entries (i.e., anything beyond the user's
known pre-existing uncommitted working-tree edits), the refactor changed
something about the user-facing config. Investigate the specific
attribute and fix before continuing.

The literal `nix path-info --derivation` hash is NOT the oracle — see
research.md R1 for why (it differs after any module move because
nix-darwin embeds `_file` paths in `options.json`).

---

## "Is `<x>` system-level or home-manager-level?"

Two grey-area cases worth pinning down because the spec calls them out:

- **`programs.zsh`**: split. System-level enable + shell integrations live
  in `hosts/macbook/system.nix`. User-level `shellAliases` and `initContent`
  live in `hosts/macbook/home/mlieberman/programs/zsh.nix`. (See
  `research.md` R7.)
- **`direnv`**: system-level enable in `hosts/macbook/system.nix`. No
  user-level direnv module today; if one is added later, put it in
  `programs/direnv.nix` under the home tree and reference this note.

For anything else, the rule of thumb: if the option's attribute path starts
with `programs.*` and you found it in nix-darwin's module options →
host-level. If it starts with `programs.*` and you found it in home-manager's
options → user-level.
