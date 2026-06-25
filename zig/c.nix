{
  pkgs,
  src,
  extraPackages ? [],
  formatDirs ? null,
  extraFormatDirs ? [],
  nixDirs ? null,
  extraNixDirs ? [],
  zigFormatDirs ? null,
  extraZigFormatDirs ? [],
  zigLintDirs ? null,
  extraZigLintDirs ? [],
  zigBuildArgs ? [
    "test"
    "--summary"
    "all"
  ],
  extraZigBuildArgs ? [],
  zigTestArgs ? zigBuildArgs,
  extraZigTestArgs ? extraZigBuildArgs,
  c ? {},
  zig ? {},
}: let
  lib = pkgs.lib;

  mkAggregate = name: drvAttrs:
    pkgs.runCommand name {} ''
      printf '%s\n' ${lib.escapeShellArgs (map builtins.toString (builtins.attrValues drvAttrs))} > /dev/null
      touch "$out"
    '';

  commonArgs = {
    inherit pkgs src extraPackages nixDirs extraNixDirs;
  };

  cChecks =
    import ../c
    (commonArgs
      // {
        inherit formatDirs extraFormatDirs;
      }
      // c);
  zigChecks =
    import ./.
    (commonArgs
      // {
        formatDirs = zigFormatDirs;
        extraFormatDirs = extraZigFormatDirs;
        lintDirs = zigLintDirs;
        extraLintDirs = extraZigLintDirs;
        zigBuildArgs = zigTestArgs;
        extraZigBuildArgs = extraZigTestArgs;
      }
      // zig);

  formatChecks = {
    c-format-check = cChecks.format-check;
    zig-format-check = zigChecks.format-check;
  };
  testChecks = {
    zig-test-check = zigChecks.test-check;
  };
  lintChecks = {
    zig-lint-check = zigChecks.lint-check;
  };
in
  {
    format-check = mkAggregate "zig-c-format-check" formatChecks;
    lint-check = zigChecks.lint-check;
    test-check = zigChecks.test-check;
    code-check = mkAggregate "zig-c-code-check" (lintChecks // testChecks);
  }
  // formatChecks
  // lintChecks
  // testChecks
