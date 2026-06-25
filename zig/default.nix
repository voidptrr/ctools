{
  pkgs,
  src,
  extraPackages ? [],
  formatDirs ? null,
  lintDirs ? null,
  nixDirs ? null,
  extraFormatDirs ? [],
  extraLintDirs ? [],
  extraNixDirs ? [],
  zigBuildArgs ? [
    "test"
    "--summary"
    "all"
  ],
  extraZigBuildArgs ? [],
  zigTestArgs ? zigBuildArgs,
  extraZigTestArgs ? extraZigBuildArgs,
}: let
  lib = pkgs.lib;

  existing = paths: builtins.filter (path: builtins.pathExists (src + "/${path}")) paths;

  defaultFormatDirs = existing ["build.zig" "build.zig.zon" "src" "tests" "examples"];
  defaultLintDirs = existing ["build.zig" "src" "tests" "examples"];
  defaultNixDirs = existing ["flake.nix" "shell.nix" "c" "zig" "nix"];

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
  effectiveLintDirs = lib.unique ((
      if lintDirs == null
      then defaultLintDirs
      else lintDirs
    )
    ++ extraLintDirs);
  formatCheck = import ../checks/zig/format.nix {
    inherit pkgs src extraPackages;
    formatDirs = effectiveFormatDirs;
    nixDirs = effectiveNixDirs;
  };

  lintCheck = import ../checks/zig/lint.nix {
    inherit pkgs src extraPackages;
    lintDirs = effectiveLintDirs;
  };

  testCheck = import ../checks/zig/test.nix {
    inherit pkgs src extraPackages;
    zigBuildArgs = zigTestArgs;
    extraZigBuildArgs = extraZigTestArgs;
  };
in {
  format-check = formatCheck;
  lint-check = lintCheck;
  test-check = testCheck;

  code-check = pkgs.runCommand "zig-code-check" {} ''
    printf '%s\n' ${builtins.toString lintCheck} ${builtins.toString testCheck} > /dev/null
    touch "$out"
  '';
}
