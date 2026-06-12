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
  nixDirs = ["."];
  sourceDirs = ["src"];
  headerDirs = ["include"];
  headerIncludeFlags = ["-Iinclude"];
  extraPackages = [
    pkgs.pkg-config
  ];
};
```

The generated checks are flake checks. Run them with `nix flake check`.

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/ctools/.github/workflows/checks.yml@v1
```
