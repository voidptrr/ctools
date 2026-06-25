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
  enableC ? null,
  enableZig ? builtins.pathExists (src + "/build.zig"),
  enableFormat ? true,
  enableLint ? true,
  enableBuild ? true,
  enableTest ? true,
  enableCTest ? true,
  nixDirs ? null,
  extraNixDirs ? [],
  cFormatDirs ? null,
  cSourceDirs ? null,
  cHeaderDirs ? null,
  extraCFormatDirs ? [],
  extraCSourceDirs ? [],
  extraCHeaderDirs ? [],
  cHeaderIncludeFlags ? [],
  extraCmakeArgs ? [],
  extraHardeningFlags ? [],
  extraHardeningLinkerFlags ? [],
  cBuildDir ? "build/hardened",
  zigFormatDirs ? null,
  zigLintDirs ? null,
  extraZigFormatDirs ? [],
  extraZigLintDirs ? [],
  zigBuildArgs ? [],
  extraZigBuildArgs ? [],
  zigTestArgs ? [
    "test"
    "--summary"
    "all"
  ],
  extraZigTestArgs ? [],
}: let
  lib = pkgs.lib;

  existing = paths: builtins.filter (path: builtins.pathExists (src + "/${path}")) paths;

  pathHasCFiles = path: let
    entries = builtins.readDir path;
  in
    lib.any (
      name: let
        type = entries.${name};
        child = path + "/${name}";
      in
        (type == "regular" && (lib.hasSuffix ".c" name || lib.hasSuffix ".h" name))
        || (type == "directory" && pathHasCFiles child)
    ) (builtins.attrNames entries);

  hasCmake = builtins.pathExists (src + "/CMakeLists.txt");
  hasCFiles =
    lib.any (
      path:
        builtins.pathExists (src + "/${path}")
        && pathHasCFiles (src + "/${path}")
    ) [
      "src"
      "tests"
      "include"
    ];
  effectiveEnableC =
    if enableC == null
    then hasCFiles || hasCmake
    else enableC;

  effectiveNixDirs = lib.unique ((
      if nixDirs == null
      then existing ["flake.nix" "shell.nix" "checks" "c" "zig" "nix"]
      else nixDirs
    )
    ++ extraNixDirs);
  effectiveCFormatDirs = lib.unique ((
      if cFormatDirs == null
      then existing ["src" "tests" "include"]
      else cFormatDirs
    )
    ++ extraCFormatDirs);
  effectiveCSourceDirs = lib.unique ((
      if cSourceDirs == null
      then existing ["src" "tests"]
      else cSourceDirs
    )
    ++ extraCSourceDirs);
  effectiveCHeaderDirs = lib.unique ((
      if cHeaderDirs == null
      then existing ["include"]
      else cHeaderDirs
    )
    ++ extraCHeaderDirs);
  effectiveZigFormatDirs = lib.unique ((
      if zigFormatDirs == null
      then existing ["build.zig" "build.zig.zon" "src" "tests" "examples"]
      else zigFormatDirs
    )
    ++ extraZigFormatDirs);
  effectiveZigLintDirs = lib.unique ((
      if zigLintDirs == null
      then existing ["build.zig" "src" "tests" "examples"]
      else zigLintDirs
    )
    ++ extraZigLintDirs);

  mkAggregate = name: drvAttrs:
    pkgs.runCommand name {} ''
      printf '%s\n' ${lib.escapeShellArgs (map builtins.toString (builtins.attrValues drvAttrs))} > /dev/null
      touch "$out"
    '';

  nixFormatCheck = import ./nix/format.nix {
    inherit pkgs src extraPackages;
    nixDirs = effectiveNixDirs;
  };
  cFormatCheck = import ./c/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = effectiveCFormatDirs;
    nixDirs = [];
  };
  cLintCheck = import ./c/lint.nix {
    inherit pkgs src extraPackages extraCmakeArgs extraHardeningFlags extraHardeningLinkerFlags;
    sourceDirs = effectiveCSourceDirs;
    headerDirs = effectiveCHeaderDirs;
    headerIncludeFlags = cHeaderIncludeFlags;
    buildDir = cBuildDir;
  };
  cTestCheck = import ./c/test.nix {
    inherit pkgs src extraPackages extraCmakeArgs extraHardeningFlags extraHardeningLinkerFlags enableCTest;
    buildDir = cBuildDir;
  };
  zigFormatCheck = import ./zig/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = effectiveZigFormatDirs;
    nixDirs = [];
  };
  zigLintCheck = import ./zig/lint.nix {
    inherit pkgs src extraPackages;
    lintDirs = effectiveZigLintDirs;
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
    lib.optionalAttrs enableFormat {nix-format-check = nixFormatCheck;}
    // lib.optionalAttrs (enableFormat && effectiveEnableC) {c-format-check = cFormatCheck;}
    // lib.optionalAttrs (enableFormat && enableZig) {zig-format-check = zigFormatCheck;};
  lintChecks =
    lib.optionalAttrs (enableLint && effectiveEnableC && hasCmake) {c-lint-check = cLintCheck;}
    // lib.optionalAttrs (enableLint && enableZig) {zig-lint-check = zigLintCheck;};
  buildChecks = lib.optionalAttrs (enableBuild && enableZig) {zig-build-check = zigBuildCheck;};
  testChecks =
    lib.optionalAttrs (enableTest && effectiveEnableC && hasCmake) {c-test-check = cTestCheck;}
    // lib.optionalAttrs (enableTest && enableZig) {zig-test-check = zigTestCheck;};
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
