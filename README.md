# ctools

Shared C project checks for Nix flakes and GitHub Actions.

## Dev Shell

```nix
devShells.default = ctools.lib.mkCShell {
  inherit pkgs;
  extraPackages = [
    pkgs.pkg-config
  ];
};
```

The default shell includes `format-code`.

## Checks

```nix
checks = ctools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  extraPackages = [
    pkgs.pkg-config
  ];
};
```

By default, `mkCChecks` uses common project paths when they exist:

- C formatting: `src`, `tests`, `include`
- C sources: `src`, `tests`
- public headers: `include`
- Nix formatting: `flake.nix`, `shell.nix`, `checks`, `packages`, `tools`, `nix`

For unusual layouts, append more paths:

```nix
checks = ctools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  extraSourceDirs = ["examples"];
  extraHeaderDirs = ["vendor/foo/include"];
  extraFormatDirs = ["examples"];
  extraNixDirs = ["config"];
};
```

Use `formatDirs`, `nixDirs`, `sourceDirs`, or `headerDirs` only when you want to
replace the defaults completely.

`code-check` runs clang-tidy for `*.c` files under `sourceDirs`, then runs a
standalone header check for `*.h` files under both `sourceDirs` and
`headerDirs`. Those directories are also added as default include search roots
for the standalone header check.

The generated checks are flake checks. Run them with `nix flake check`.

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/ctools/.github/workflows/checks.yml@<commit-sha>
```
