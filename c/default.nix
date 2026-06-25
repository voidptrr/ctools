{
  pkgs,
  src,
  extraPackages ? [],
  formatDirs ? null,
  nixDirs ? null,
  sourceDirs ? null,
  headerDirs ? null,
  extraFormatDirs ? [],
  extraNixDirs ? [],
  extraSourceDirs ? [],
  extraHeaderDirs ? [],
  headerIncludeFlags ? [],
  extraCmakeArgs ? [],
  extraHardeningFlags ? [],
  extraHardeningLinkerFlags ? [],
  buildDir ? "build/hardened",
  enableCTest ? true,
}: let
  lib = pkgs.lib;

  existing = paths: builtins.filter (path: builtins.pathExists (src + "/${path}")) paths;

  defaultFormatDirs = existing ["src" "tests" "include"];
  defaultNixDirs = existing ["flake.nix" "shell.nix" "c" "zig" "nix"];
  defaultSourceDirs = existing ["src" "tests"];
  defaultHeaderDirs = existing ["include"];

  effectiveFormatDirs = lib.unique ((
      if formatDirs == null
      then defaultFormatDirs
      else formatDirs
    )
    ++ extraFormatDirs);
  effectiveNixDirs = lib.unique ((
      if nixDirs == null
      then defaultNixDirs
      else nixDirs
    )
    ++ extraNixDirs);
  effectiveSourceDirs = lib.unique ((
      if sourceDirs == null
      then defaultSourceDirs
      else sourceDirs
    )
    ++ extraSourceDirs);
  effectiveHeaderDirs = lib.unique ((
      if headerDirs == null
      then defaultHeaderDirs
      else headerDirs
    )
    ++ extraHeaderDirs);
  formatCheck = import ../checks/c/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = effectiveFormatDirs;
    nixDirs = effectiveNixDirs;
  };

  lintCheck = import ../checks/c/lint.nix {
    inherit
      pkgs
      src
      extraPackages
      headerIncludeFlags
      extraCmakeArgs
      extraHardeningFlags
      extraHardeningLinkerFlags
      buildDir
      ;
    sourceDirs = effectiveSourceDirs;
    headerDirs = effectiveHeaderDirs;
  };

  testCheck = import ../checks/c/test.nix {
    inherit
      pkgs
      src
      extraPackages
      extraCmakeArgs
      extraHardeningFlags
      extraHardeningLinkerFlags
      buildDir
      enableCTest
      ;
  };
in {
  format-check = formatCheck;
  lint-check = lintCheck;
  test-check = testCheck;

  code-check = pkgs.runCommand "c-code-check" {} ''
    printf '%s\n' ${builtins.toString lintCheck} ${builtins.toString testCheck} > /dev/null
    touch "$out"
  '';
}
