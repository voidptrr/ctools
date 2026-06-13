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

## Checks

```nix
checks = ctools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  formatDirs = ["src" "tests" "include"];
  nixDirs = ["flake.nix" "shell.nix" "checks"];
  sourceDirs = ["src"];
  headerDirs = ["include"];
  extraPackages = [
    pkgs.pkg-config
  ];
};
```

`code-check` runs clang-tidy for `*.c` files under `sourceDirs`, then runs a
standalone header check for `*.h` files under both `sourceDirs` and
`headerDirs`. Those directories are also added as default include search roots
for the standalone header check.

The generated checks are flake checks. Run them with `nix flake check`.

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/ctools/.github/workflows/checks.yml@v1
```
