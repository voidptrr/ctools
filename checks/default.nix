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
  nixDirs ? null,
  extraNixDirs ? [],
  c ? {},
  zig ? {},
  enableC ? builtins.pathExists (src + "/CMakeLists.txt"),
  enableCFormat ? null,
  enableCLint ? enableC,
  enableCTestCheck ? enableC,
  enableZig ? builtins.pathExists (src + "/build.zig"),
  enableZigLint ? enableZig,
  enableZigTest ? enableZig,
}: let
  lib = pkgs.lib;

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
  effectiveEnableCFormat =
    if enableCFormat == null
    then enableC || hasCFiles
    else enableCFormat;

  mkAggregate = name: drvAttrs:
    pkgs.runCommand name {} ''
      printf '%s\n' ${lib.escapeShellArgs (map builtins.toString (builtins.attrValues drvAttrs))} > /dev/null
      touch "$out"
    '';

  commonArgs = {
    inherit pkgs src;
    extraPackages = extraPackages;
    nixDirs = nixDirs;
    extraNixDirs = extraNixDirs;
  };

  cChecks = import ../c (commonArgs // c);
  zigChecks = import ../zig (commonArgs // zig);

  formatChecks =
    (lib.optionalAttrs effectiveEnableCFormat {c-format-check = cChecks.format-check;})
    // (lib.optionalAttrs enableZig {zig-format-check = zigChecks.format-check;});
  lintChecks =
    (lib.optionalAttrs enableCLint {c-lint-check = cChecks.lint-check;})
    // (lib.optionalAttrs enableZigLint {zig-lint-check = zigChecks.lint-check;});
  testChecks =
    (lib.optionalAttrs enableCTestCheck {c-test-check = cChecks.test-check;})
    // (lib.optionalAttrs enableZigTest {zig-test-check = zigChecks.test-check;});
  codeChecks = lintChecks // testChecks;
in
  {
    format-check = mkAggregate "format-check" formatChecks;
    lint-check = mkAggregate "lint-check" lintChecks;
    test-check = mkAggregate "test-check" testChecks;
    code-check = mkAggregate "code-check" codeChecks;
  }
  // formatChecks
  // lintChecks
  // testChecks
