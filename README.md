# vtools

Small Nix helpers for C, Zig, and C projects built with Zig.

The public API is intentionally small:

- `vtools.lib.mkShell`
- `vtools.lib.mkChecks`
- `packages.<system>.format-code`

The check implementation is still split internally by language, but users should
not need language-specific helper functions.

## Dev Shell

```nix
devShells.default = vtools.lib.mkShell {
  inherit pkgs;
  src = ./.;
  extraPackages = [pkgs.pkg-config];
};
```

`mkShell` detects C files or `CMakeLists.txt` to include C tooling, and detects
`build.zig` to include Zig. Override detection with `enableC` and `enableZig`.

```nix
devShells.default = vtools.lib.mkShell {
  inherit pkgs;
  src = ./.;
  enableC = true;
  enableZig = true;
};
```

## Checks

Use one checks helper for C, Zig, and Zig-built C projects:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
};
```

Default detection:

- `enableC` is true when C files exist under `src`, `tests`, or `include`, or when `CMakeLists.txt` exists.
- `enableZig` is true when `build.zig` exists.
- CMake lint/test checks only run when `CMakeLists.txt` exists.
- Zig checks run through `zig build` and `zig build test --summary all`.

Force a project shape explicitly:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
  enableC = true;
  enableZig = true;
};
```

This is the normal setup for a C project built by Zig: C formatting is enabled
from the C files, and Zig build/test checks are enabled from `build.zig`.

## Check Outputs

`mkChecks` returns aggregate checks:

- `format-check`
- `lint-check`
- `build-check`
- `test-check`
- `code-check`, which aggregates lint, build, and test

It also returns language-specific checks when enabled:

- `nix-format-check`
- `c-format-check`
- `c-lint-check`, only for CMake projects
- `c-test-check`, only for CMake projects
- `zig-format-check`
- `zig-lint-check`
- `zig-build-check`
- `zig-test-check`

## What Checks Do

Nix formatting uses Alejandra over `nixDirs`.

C formatting uses `clang-format --dry-run --Werror` over C files under
`cFormatDirs`. C lint/test checks are CMake-based. `c-lint-check` configures,
builds, and runs `clang-tidy`; `c-test-check` configures, builds, and runs
`ctest` unless `enableCTest = false`.

Zig formatting uses `zig fmt --check`; directories are passed directly to Zig,
so Zig handles recursion. Zig lint uses `zig ast-check` over discovered Zig
files. Zig build and test checks run:

```sh
zig build
zig build test --summary all
```

Both commands use temporary local and global Zig cache directories inside the Nix
build sandbox.

## Common Options

Disable an entire phase:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
  enableLint = false;
  enableBuild = true;
  enableTest = true;
};
```

Disable CTest while still building CMake tests:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
  enableCTest = false;
};
```

Append Zig build options:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
  extraZigBuildArgs = ["-Doptimize=ReleaseSafe"];
  extraZigTestArgs = ["-Dfoo=true"];
};
```

Replace default paths when needed:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
  nixDirs = ["flake.nix" "nix"];
  cFormatDirs = ["src" "include" "examples"];
  zigFormatDirs = ["build.zig" "tools"];
};
```

Useful path options:

- `nixDirs`, `extraNixDirs`
- `cFormatDirs`, `extraCFormatDirs`
- `cSourceDirs`, `extraCSourceDirs`
- `cHeaderDirs`, `extraCHeaderDirs`
- `zigFormatDirs`, `extraZigFormatDirs`
- `zigLintDirs`, `extraZigLintDirs`

## Formatter

The package `format-code` formats Nix, C, and Zig files in-place:

```sh
nix run github:voidptrr/vtools#format-code
```

Runtime switches:

```sh
CTOOLS_ENABLE_C=0 format-code
CTOOLS_ENABLE_ZIG=0 format-code
CTOOLS_C_FORMAT_DIRS="src include" format-code
CTOOLS_ZIG_FORMAT_DIRS="build.zig src" format-code
CTOOLS_NIX_DIRS="flake.nix nix" format-code
```

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/vtools/.github/workflows/checks.yml@<commit-sha>
```
