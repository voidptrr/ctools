# MIT License
#
# Copyright (c) 2026 Tommaso Bruno
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
{
  pkgs,
  src,
  extraPackages ? [],
  enableNixFormat ? false,
  enableCFormat ? false,
  enableCLint ? false,
  enableCTest ? false,
  enableZigFormat ? false,
  enableZigLint ? false,
  enableZigBuild ? false,
  enableZigTest ? false,
  nixDirs ? ["."],
  cFormatDirs ? [
    "src"
    "tests"
    "include"
  ],
  cSourceDirs ? [
    "src"
    "tests"
  ],
  cHeaderDirs ? ["include"],
  cHeaderIncludeFlags ? [],
  extraCmakeArgs ? [],
  extraHardeningFlags ? [],
  extraHardeningLinkerFlags ? [],
  cBuildDir ? "build/hardened",
  zigFormatDirs ? [
    "build.zig"
    "build.zig.zon"
    "src"
    "tests"
    "examples"
  ],
  zigLintDirs ? [
    "build.zig"
    "src"
    "tests"
    "examples"
  ],
  zigBuildArgs ? [],
  zigTestArgs ? [
    "test"
    "--summary"
    "all"
  ],
  extraZigBuildArgs ? [],
  extraZigTestArgs ? [],
}: let
  lib = pkgs.lib;

  mkAggregate = name: drvAttrs:
    pkgs.runCommand name {} ''
      printf '%s\n' ${lib.escapeShellArgs (map builtins.toString (builtins.attrValues drvAttrs))} > /dev/null
      touch "$out"
    '';

  nixFormatCheck = import ./nix/format.nix {
    inherit pkgs src extraPackages;
    inherit nixDirs;
  };
  cFormatCheck = import ./c/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = cFormatDirs;
    nixDirs = [];
  };
  cLintCheck = import ./c/lint.nix {
    inherit pkgs src extraPackages extraCmakeArgs extraHardeningFlags extraHardeningLinkerFlags;
    sourceDirs = cSourceDirs;
    headerDirs = cHeaderDirs;
    headerIncludeFlags = cHeaderIncludeFlags;
    buildDir = cBuildDir;
  };
  cTestCheck = import ./c/test.nix {
    inherit pkgs src extraPackages extraCmakeArgs extraHardeningFlags extraHardeningLinkerFlags;
    buildDir = cBuildDir;
  };
  zigFormatCheck = import ./zig/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = zigFormatDirs;
    nixDirs = [];
  };
  zigLintCheck = import ./zig/lint.nix {
    inherit pkgs src extraPackages;
    lintDirs = zigLintDirs;
  };
  zigBuildCheck = import ./zig/build.nix {
    inherit pkgs src extraPackages zigBuildArgs extraZigBuildArgs;
  };
  zigTestCheck = import ./zig/test.nix {
    inherit pkgs src extraPackages;
    zigBuildArgs = zigTestArgs;
    extraZigBuildArgs = extraZigTestArgs;
  };

  formatChecks =
    lib.optionalAttrs enableNixFormat {nix-format-check = nixFormatCheck;}
    // lib.optionalAttrs enableCFormat {c-format-check = cFormatCheck;}
    // lib.optionalAttrs enableZigFormat {zig-format-check = zigFormatCheck;};
  lintChecks =
    lib.optionalAttrs enableCLint {c-lint-check = cLintCheck;}
    // lib.optionalAttrs enableZigLint {zig-lint-check = zigLintCheck;};
  buildChecks = lib.optionalAttrs enableZigBuild {zig-build-check = zigBuildCheck;};
  testChecks =
    lib.optionalAttrs enableCTest {c-test-check = cTestCheck;}
    // lib.optionalAttrs enableZigTest {zig-test-check = zigTestCheck;};
  codeChecks = lintChecks // buildChecks // testChecks;
in
  {
    format-check = mkAggregate "format-check" formatChecks;
    lint-check = mkAggregate "lint-check" lintChecks;
    build-check = mkAggregate "build-check" buildChecks;
    test-check = mkAggregate "test-check" testChecks;
    code-check = mkAggregate "code-check" codeChecks;
  }
  // formatChecks
  // lintChecks
  // buildChecks
  // testChecks
