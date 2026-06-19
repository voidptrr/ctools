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
  formatDirs ? null,
  nixDirs ? null,
  extraFormatDirs ? [],
  extraNixDirs ? [],
  zigTestArgs ? [
    "test"
    "--summary"
    "all"
  ],
}: let
  lib = pkgs.lib;

  existing = paths: builtins.filter (path: builtins.pathExists (src + "/${path}")) paths;

  defaultFormatDirs = existing ["src" "tests" "include"];
  defaultNixDirs = existing ["flake.nix" "shell.nix" "checks" "packages" "tools" "nix"];

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
in {
  format-check = import ./format.nix {
    inherit pkgs src extraPackages;
    formatDirs = effectiveFormatDirs;
    nixDirs = effectiveNixDirs;
  };

  code-check = import ./zig-code.nix {
    inherit pkgs src extraPackages zigTestArgs;
  };
}
