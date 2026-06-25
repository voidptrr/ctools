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
  zigBuildArgs ? [
    "test"
    "--summary"
    "all"
  ],
  extraZigBuildArgs ? [],
}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;
  effectiveZigBuildArgs = zigBuildArgs ++ extraZigBuildArgs;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
  pkgs.runCommand "zig-test-check" {
    nativeBuildInputs = with pkgs;
      [
        zig
      ]
      ++ extraPackages;
  } ''
    ${copySource}

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache"

    zig build \
      --cache-dir "$ZIG_LOCAL_CACHE_DIR" \
      --global-cache-dir "$ZIG_GLOBAL_CACHE_DIR" \
      ${shellArgs effectiveZigBuildArgs}

    touch "$out"
  ''
