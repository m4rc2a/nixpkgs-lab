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
| `rustxl` | `rustxl` | Terminal-based spreadsheet (binary: `xl`) |

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
nix build github:m4rc2a/nixpkgs-lab#rustxl
```

## Local development

```sh
nix develop
nix fmt
nix build .#sapcli .#pyodata .#rustxl
nix flake check --no-build
nix run .#sapcli -- --version
nix run .#rustxl -- --version
```

## Adding a package

### 1. Generate the expression

Run `nix-init` from the repository root and pass the **output file path**.
With `-C` (`--commit`) nix-init commits the result as
`<name>: init at <version>`.

```sh
nix-init -C -u <upstream-url> pkgs/by-name/<shard>/<name>/package.nix

# Example
nix-init -C -u https://github.com/only-using-ai/rustxl \
  pkgs/by-name/ru/rustxl/package.nix
```

`-C` only commits when:

- you are in the repository root (`.git` in the current directory),
- the path is relative and has no leading `./`,
- the path matches `pkgs/by-name/<shard>/<name>/package.nix` exactly.

If you pass a directory, `nix-init` writes `default.nix` instead and creates no
commit. `pkgs/by-name` is only auto-discovered *inside* nixpkgs; in this
repository the path is a convention and the overlay entry below is what exposes
the package.

Python modules keep the classic layout, use `default.nix`, and are not
auto-committed:

```sh
nix-init -u <upstream-url> pkgs/development/python-modules/<name>
```

### 2. Fix up the generated file

`nix-init` leaves FIXMEs behind, and not everything it guesses is correct:

- `license`: if upstream ships no `LICENSE` file, check the README,
  `Cargo.toml`, or `pyproject.toml`. Do not leave `unfree` in place without a
  comment explaining why.
- `mainProgram`: must match the installed binary, which is often not the
  package name (e.g. the `rustxl` repo installs `bin/xl`).
- `maintainers`: `[ ]` is fine for lab-only packages.
- Tests: if upstream tests fail, skip only the broken test instead of
  disabling all of them:

  ```nix
  checkFlags = [ "--skip=module::tests::test_name" ];
  ```

- Runtime dependencies: programs that shell out to other tools need them in
  `buildInputs`/`runtimeDependencies` as appropriate.

### 3. Wire it up

Add the package to `overlay.nix`:

```nix
rustxl = final.callPackage ./pkgs/by-name/ru/rustxl/package.nix {};
```

Python modules go through the `python3Packages` override scope:

```nix
python3Packages = prev.python3Packages.overrideScope (self: super: {
  pyodata = self.callPackage ./pkgs/development/python-modules/pyodata {};
});
```

Then expose it in `flake.nix` under both `packages` and `checks` so it is
buildable via `nix build .#<name>` and covered by CI, and add a row to the
[Packages](#packages) table.

### 4. Test

```sh
nix fmt
nix build .#<name>
nix run .#<name> -- --version
nix flake check --no-build
```

`nix flake check --no-build` evaluates every package for all systems; CI builds
`x86_64-linux`.

### 5. Commit

With `-C`, `nix-init` already created the initial commit, but it contains the
raw output including FIXMEs. After fixing the file up, amend it:

```sh
git add pkgs/by-name/<shard>/<name>/package.nix
git commit --amend
```

Without `-C`, commit normally with `<name>: init at <version>`.

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

GitHub Actions evaluates the flake and builds all packages on `x86_64-linux`.
`aarch64-linux` is exposed but not built in CI.

## License

MIT
