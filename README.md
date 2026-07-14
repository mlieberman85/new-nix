# mlieberman / new-nix

Personal nix-darwin + home-manager flake for the `macbook` host
(`aarch64-darwin`, user `mlieberman`). The Nix daemon is managed by the
[Determinate Nix installer](https://determinate.systems/), so nix-darwin's
own daemon management is explicitly disabled (`nix.enable = false`) —
**don't flip that without amending the constitution first**
(`.specify/memory/constitution.md` Principle IV).

## Layout

```text
flake.nix                                  # inputs, outputs, darwinConfigurations wiring (≤ 60 lines)
hosts/
└── macbook/
    ├── default.nix                        # host entry: imports, system.{primaryUser,stateVersion}, allowUnfree, fonts, systemPath, home-manager toggles
    ├── nix.nix                            # Determinate boundary (nix.enable = false + experimental features)
    ├── system.nix                         # programs.zsh (system-level), programs.direnv, users.users.mlieberman
    ├── packages.nix                       # environment.systemPackages + the gdk (google-cloud-sdk + GKE auth) let-binding
    ├── homebrew.nix                       # homebrew.{enable, onActivation, brews, casks, taps}
    └── home/
        └── mlieberman/
            ├── default.nix                # home-manager user entry: home.stateVersion + installSpecKit activation + imports
            └── programs/
                ├── alacritty.nix
                ├── nushell.nix
                ├── zsh.nix                # user-level zsh (system-level enable lives in ../../system.nix)
                ├── zoxide.nix
                ├── wezterm.nix
                ├── zellij.nix
                ├── helix.nix
                └── neovim.nix
```

## Where do I add a…

| I want to add… | Edit this file | How |
|---|---|---|
| A nixpkgs CLI tool | `hosts/macbook/packages.nix` | append to `environment.systemPackages` |
| A Homebrew brew | `hosts/macbook/homebrew.nix` | append to `homebrew.brews` |
| A Homebrew cask | `hosts/macbook/homebrew.nix` | append to `homebrew.casks` |
| A Homebrew tap | `hosts/macbook/homebrew.nix` | append to `homebrew.taps` (only if a brew/cask above needs it — Principle III) |
| A new home-manager program | new file `hosts/macbook/home/mlieberman/programs/<name>.nix` + add to `imports` in `hosts/macbook/home/mlieberman/default.nix` | `{ ... }: { programs.<name>.enable = true; }` |
| A tweak to an existing program | `hosts/macbook/home/mlieberman/programs/<name>.nix` | edit in place |
| A new `$PATH` entry (`environment.systemPath`) | `hosts/macbook/default.nix` — NOT system.nix | append to the list. See `specs/001-modular-nix-config/research.md` R9 for why this option stays in default.nix. |
| A system-level nix-darwin option | `hosts/macbook/system.nix` (or `default.nix` for identity options like `primaryUser`, `stateVersion`) | by attribute path |
| A change to the Determinate boundary | `hosts/macbook/nix.nix` | `nix.enable` MUST stay `false` (Principle IV) |
| A new flake input | `flake.nix` | also requires a constitutional sanity check (Principle II) |
| A second host | new tree `hosts/<newhost>/` + new entry under `darwinConfigurations` in `flake.nix` | mirror `hosts/macbook/` layout; do NOT modify any existing file under `hosts/macbook/` |

### Grey areas

- **`programs.zsh`** is split. Nix-darwin's system-level enable +
  `enableSyntaxHighlighting` + `enableFzfHistory` live in
  `hosts/macbook/system.nix`. The user-level `shellAliases` and
  `initContent` live in `hosts/macbook/home/mlieberman/programs/zsh.nix`.
  Rule of thumb: nix-darwin's `programs.*` options → host-level;
  home-manager's `programs.*` options → user-level.
- **`direnv`** is system-level only today (in `system.nix`). If you ever
  need user-level direnv config, add `programs/direnv.nix` under the home
  tree.
- **Tooling that crosses Nix and Homebrew** (e.g. `yabai`, `skhd`): brew
  side in `hosts/macbook/homebrew.nix`. If you later add a dotfile
  config for one of these, put it under the home tree at a path
  containing the tool's name so it remains locatable by `fd <name>`.

## Build & switch

The canonical workflow is in `.specify/memory/constitution.md`
(Principle V + the Development Workflow section). Short form:

```sh
nixpkgs-fmt flake.nix hosts/macbook/**/*.nix
darwin-rebuild build --flake .#macbook   # MUST succeed first
darwin-rebuild switch --flake .#macbook
# verify in a fresh shell; if broken: darwin-rebuild --rollback
```

## Where are the principles and decisions?

- **Constitution** (governing principles): `.specify/memory/constitution.md`
- **Modular-layout spec / plan / decisions**: `specs/001-modular-nix-config/`
  (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
  `tasks.md`). Two real implementation discoveries are documented there
  worth knowing about:
  - **R1**: SC-004 cannot be a strict system-derivation `.drv` hash check
    — nix-darwin embeds `_file` paths in `darwin-option`'s `options.json`,
    so any module move changes the .drv hash even when functionally
    identical. The oracle is a curated config snapshot instead.
  - **R9**: `environment.systemPath` MUST live in `hosts/macbook/default.nix`,
    not in a separate module. Splitting it shifts the merge priority
    against nix-darwin's multi-priority defaults and silently changes
    `$PATH` precedence.
