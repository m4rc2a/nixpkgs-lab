# nixpkgs-lab

Experimental Nix packages and an overlay flake.

> [!WARNING]
> Everything here is experimental. Packages may be broken, change, or disappear.
> Pin the flake input to a commit if you depend on it.

## Packages

| Package | Attribute | Notes |
| --- | --- | --- |
| `sapcli` | `sapcli` | Command line interface to SAP products |
| `pyodata` | `python3Packages.pyodata`, `pyodata` | Python OData client |

## Usage

### As a flake input

```nix
inputs.nixpkgs-lab = {
  url = "github:m4rc2a/nixpkgs-lab";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Apply the overlay:

```nix
nixpkgs.overlays = [ inputs.nixpkgs-lab.overlays.default ];
```

Or, if you build your own package set:

```nix
import nixpkgs {
  inherit system;
  overlays = [ inputs.nixpkgs-lab.overlays.default ];
};
```

### Direct use

```sh
nix run github:m4rc2a/nixpkgs-lab#sapcli -- --version
nix build github:m4rc2a/nixpkgs-lab#sapcli
nix build github:m4rc2a/nixpkgs-lab#pyodata
```

## Local development

```sh
nix develop
nix fmt
nix build .#sapcli .#pyodata
nix flake check --no-build
nix run .#sapcli -- --version
```

## Adding a package

1. Generate a package expression with `nix-init`.
2. Place it under `pkgs/by-name/<two-letter-prefix>/<name>/package.nix` for
   top-level packages, or `pkgs/development/python-modules/<name>/default.nix`
   for Python modules.
3. Add it to `overlay.nix`.
4. Add it to `packages` and `checks` in `flake.nix`.
5. Test it:
   ```sh
   nix build .#<name>
   ```
6. Commit and push.

## Updating

- Update nixpkgs: `nix flake update`
- Update tagged packages: `nix-update <name>`
- `sapcli` upstream only has a `latest` tag, so its version is commit-based.
  Update it with `nix-update --version=branch sapcli` and adjust the version if
  needed.

Consumers should update deliberately:

```sh
nix flake update nixpkgs-lab
```

## Integration notes

`hm-config` and `nixos-config` are separate repos. Each needs its own
`nixpkgs-lab` input; there is no nested `hm-config` input in `nixos-config`.

For `hm-config`, apply the overlay in `pkgsFor`:

```nix
pkgsFor = system: import nixpkgs {
  inherit system;
  overlays = [ inputs.nixpkgs-lab.overlays.default ];
  config = { ... };
};
```

For `nixos-config`, apply it in a NixOS module:

```nix
{ flake, ... }: {
  nixpkgs.overlays = [ flake.inputs.nixpkgs-lab.overlays.default ];
}
```

## CI

GitHub Actions evaluates the flake and builds both packages on `x86_64-linux`.
`aarch64-linux` is exposed but not built in CI.

## License

MIT
