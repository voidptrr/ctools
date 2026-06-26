<!--
MIT License

Copyright (c) 2026 Tommaso Bruno

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->

# vtools

Small Nix helpers for projects that use C, Zig, or both.

The interface is explicit. Nothing is enabled by scanning your source tree, and
all language/check options are off by default. Turn on exactly the tools or
checks you want.

Public API:

- `vtools.lib.mkShell`
- `vtools.lib.mkChecks`
- `vtools.packages.${system}.format-code`

## Dev Shells

`mkShell` creates a development shell from two toolchain flags:

```nix
devShells.default = vtools.lib.mkShell {
  inherit pkgs;
  enableC = true;
  enableZig = true;
  extraPackages = [pkgs.pkg-config];
};
```

Defaults:

- `enableC = false`
- `enableZig = false`

`enableC` adds:

- `gcc`
- `cmake`
- `ninja`
- `clang-tools`

`enableZig` adds:

- `zig`
- `zls`

You can still pass normal shell inputs:

```nix
devShells.default = vtools.lib.mkShell {
  inherit pkgs;
  enableC = true;
  buildInputs = [pkgs.openssl];
  nativeBuildInputs = [pkgs.pkg-config];
};
```

## Checks

`mkChecks` returns flake checks. Every check is opt-in:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableCFormat = true;
  enableCLint = true;
  enableCTest = true;
};
```

Available check flags:

- `enableNixFormat`
- `enableCFormat`
- `enableCLint`
- `enableCTest`
- `enableZigFormat`
- `enableZigLint`
- `enableZigBuild`
- `enableZigTest`

All default to `false`.

## Check Outputs

`mkChecks` always returns aggregate checks:

- `format-check`
- `lint-check`
- `build-check`
- `test-check`
- `code-check`, which aggregates lint, build, and test

It also returns enabled concrete checks:

- `nix-format-check`
- `c-format-check`
- `c-lint-check`
- `c-test-check`
- `zig-format-check`
- `zig-lint-check`
- `zig-build-check`
- `zig-test-check`

## C Checks

C formatting runs `clang-format --dry-run --Werror` over C and header files.

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableCFormat = true;
  cFormatDirs = ["src" "include" "tests"];
};
```

C lint configures a hardened CMake/Ninja build, builds it, then runs
`clang-tidy` over C sources and headers.

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableCLint = true;
  cSourceDirs = ["src" "tests"];
  cHeaderDirs = ["include"];
  extraCmakeArgs = ["-DBUILD_TESTING=ON"];
};
```

CTest configures and builds the CMake project, then runs:

```sh
ctest --test-dir build/hardened --output-on-failure
```

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableCTest = true;
};
```

Useful C options:

- `cFormatDirs`, default `["src" "tests" "include"]`
- `cSourceDirs`, default `["src" "tests"]`
- `cHeaderDirs`, default `["include"]`
- `cHeaderIncludeFlags`, default `[]`
- `extraCmakeArgs`, default `[]`
- `extraHardeningFlags`, default `[]`
- `extraHardeningLinkerFlags`, default `[]`
- `cBuildDir`, default `"build/hardened"`

## Zig Checks

Zig formatting runs `zig fmt --check`:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableZigFormat = true;
  zigFormatDirs = ["build.zig" "src" "tests"];
};
```

Zig lint runs `zig ast-check` over discovered `.zig` files:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableZigLint = true;
  zigLintDirs = ["build.zig" "src" "tests"];
};
```

Zig build and test run through `zig build`:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableZigBuild = true;
  enableZigTest = true;
  extraZigBuildArgs = ["-Doptimize=ReleaseSafe"];
  extraZigTestArgs = ["-Dfoo=true"];
};
```

Useful Zig options:

- `zigFormatDirs`, default `["build.zig" "build.zig.zon" "src" "tests" "examples"]`
- `zigLintDirs`, default `["build.zig" "src" "tests" "examples"]`
- `zigBuildArgs`, default `[]`
- `extraZigBuildArgs`, default `[]`
- `zigTestArgs`, default `["test" "--summary" "all"]`
- `extraZigTestArgs`, default `[]`

## Nix Formatting

Enable Nix formatting explicitly:

```nix
checks = vtools.lib.mkChecks {
  inherit pkgs;
  src = ./.;

  enableNixFormat = true;
  nixDirs = ["flake.nix" "shell.nix" "nix"];
};
```

## Formatter Package

`format-code` formats files in place. Its language flags are also off by
default, so expose a project-specific package with the languages you want:

```nix
packages.format-code = vtools.packages.${system}.format-code.override {
  enableNix = true;
  enableC = true;
  enableZig = true;

  nixDirs = ["flake.nix" "nix"];
  cFormatDirs = ["src" "include"];
  zigFormatDirs = ["build.zig" "src"];
};
```

Then run:

```sh
nix run .#format-code
```

## GitHub Actions

```yaml
jobs:
  checks:
    uses: owner/vtools/.github/workflows/checks.yml@<commit-sha>
```
