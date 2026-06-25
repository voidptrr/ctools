# vtools

Shared C and Zig project tooling for Nix flakes and GitHub Actions.

## Dev Shells

Use `mkShell` when the project may be C, Zig, or both:

```nix
devShells.default = vtools.lib.mkShell {
  inherit pkgs;
  src = ./.;
};
```

The shell includes `format-code`, Nix formatting tools, and the detected
language toolchains. C is enabled when `CMakeLists.txt` or C files under common
source directories exist. Zig is enabled when `build.zig` exists.

Use language-specific shells when detection is not wanted:

```nix
devShells.default = vtools.lib.mkCShell {
  inherit pkgs;
  nativeBuildInputs = [pkgs.pkg-config];
  buildInputs = [pkgs.openssl pkgs.zlib];
};
```

```nix
devShells.default = vtools.lib.mkZigShell {
  inherit pkgs;
};
```

Use `extraPackages` for additional tools that do not need to be classified as
`nativeBuildInputs` or `buildInputs`.

## Checks

Use `mkChecks` for automatic C/Zig check selection:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
};
```

It exposes aggregate checks:

- `format-check`
- `lint-check`
- `test-check`
- `code-check`, which aggregates lint and test for compatibility

It also exposes language-specific checks when enabled:

- `c-format-check`, `c-lint-check`, `c-test-check`
- `zig-format-check`, `zig-lint-check`, `zig-test-check`

Detection defaults:

- C formatting is enabled when C files exist under `src`, `tests`, or `include`.
- C lint/test checks are enabled when `CMakeLists.txt` exists.
- Zig format/lint/test checks are enabled when `build.zig` exists.

Override detection with `enableCFormat`, `enableCLint`, `enableCTestCheck`,
`enableZig`, `enableZigLint`, and `enableZigTest`.

## C Checks

Use `mkCChecks` for CMake-built C projects:

```nix
checks = vtools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  extraPackages = [pkgs.pkg-config];
};
```

Defaults:

- C formatting dirs: `src`, `tests`, `include`
- C source dirs: `src`, `tests`
- C header dirs: `include`
- Nix formatting paths: `flake.nix`, `shell.nix`, `c`, `zig`, `nix`

Append extra paths:

```nix
checks = vtools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  extraSourceDirs = ["examples"];
  extraHeaderDirs = ["vendor/foo/include"];
  extraFormatDirs = ["examples"];
  extraNixDirs = ["config"];
};
```

Use `formatDirs`, `nixDirs`, `sourceDirs`, or `headerDirs` to replace defaults.

`c-format-check` runs Alejandra for Nix paths and `clang-format --dry-run
--Werror` for C files. `c-lint-check` configures/builds with CMake and runs
`clang-tidy`. `c-test-check` configures/builds with CMake and runs `ctest` by
default.

Disable CTest while still building:

```nix
checks = vtools.lib.mkCChecks {
  inherit pkgs;
  src = ./.;
  enableCTest = false;
};
```

## Zig Checks

Use `mkZigChecks` for Zig projects:

```nix
checks = vtools.lib.mkZigChecks {
  inherit pkgs;
  src = ./.;
};
```

Defaults:

- Zig format paths: `build.zig`, `build.zig.zon`, `src`, `tests`, `examples`
- Zig lint paths: `build.zig`, `src`, `tests`, `examples`
- Nix formatting paths: `flake.nix`, `shell.nix`, `c`, `zig`, `nix`

`zig-format-check` runs Alejandra for Nix paths and `zig fmt --check` for Zig
paths. `zig fmt` receives files/directories directly, so directories are handled
recursively by Zig. `zig-lint-check` runs `zig ast-check` over discovered Zig
files. `zig-test-check` runs:

```sh
zig build \
  --cache-dir "$TMPDIR/zig-cache" \
  --global-cache-dir "$TMPDIR/zig-global-cache" \
  test --summary all
```

Append Zig build options after `test --summary all`:

```nix
checks = vtools.lib.mkZigChecks {
  inherit pkgs;
  src = ./.;
  extraZigBuildArgs = ["-Dfoo=true"];
};
```

Use `zigBuildArgs` only when replacing the default build tail entirely.

## Zig-Built C

C projects built by Zig usually do not need a special helper. Use `mkChecks`;
it detects C files for C formatting and `build.zig` for Zig format, lint, and
test checks:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;
};
```

`mkZigCChecks` is still available as an explicit wrapper when you want to force
that composition without relying on detection. It combines C formatting with Zig
format/lint/test checks, does not require `CMakeLists.txt`, and runs tests
through `zig build`.

## Formatter

The flake exposes one formatter implementation:

- `packages.<system>.format-code`
- `packages.<system>.c-format-code`
- `packages.<system>.zig-format-code`

`c-format-code` and `zig-format-code` are thin wrappers around the root
formatter with one language disabled.

Root formatter defaults:

- Nix paths: `CTOOLS_NIX_DIRS`, default `.`
- C paths: `CTOOLS_C_FORMAT_DIRS`, default `src tests include`
- Zig paths: `CTOOLS_ZIG_FORMAT_DIRS`, default `build.zig build.zig.zon src tests examples`

Runtime switches:

```sh
CTOOLS_ENABLE_C=0 format-code
CTOOLS_ENABLE_ZIG=0 format-code
CTOOLS_ZIG_FORMAT_DIRS="build.zig src" format-code
```

Package construction switches:

```nix
format-code = import "${vtools}/format-code.nix" {
  inherit pkgs;
  enableC = true;
  enableZig = false;
};
```

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/vtools/.github/workflows/checks.yml@<commit-sha>
```
