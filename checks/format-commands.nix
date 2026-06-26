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
{pkgs}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;
  optionalFlag = check: flag: lib.optionalString check "${flag} ";
in {
  nix = {
    nixDirs ? [],
    check ? true,
  }: ''
    nix_dirs=(${shellArgs nixDirs})

    if [ "''${#nix_dirs[@]}" -gt 0 ]; then
      alejandra ${optionalFlag check "--check"}"''${nix_dirs[@]}"
    fi
  '';

  c = {
    formatDirs ? [],
    check ? true,
  }: ''
    format_dirs=(${shellArgs formatDirs})

    find_existing_c_files() {
      for dir in "''${format_dirs[@]}"; do
        [ ! -d "$dir" ] || find "$dir" -type f \( -name '*.c' -o -name '*.h' \) -print0
      done
    }

    find_existing_c_files | xargs -0 --no-run-if-empty clang-format ${
      if check
      then "--dry-run --Werror"
      else "-i"
    }
  '';

  zig = {
    formatDirs ? [],
    check ? true,
  }: ''
    format_dirs=(${shellArgs formatDirs})

    append_existing_zig_paths() {
      for path in "''${format_dirs[@]}"; do
        [ ! -e "$path" ] || existing_zig_paths+=("$path")
      done
    }

    existing_zig_paths=()
    append_existing_zig_paths
    if [ "''${#existing_zig_paths[@]}" -gt 0 ]; then
      zig fmt ${optionalFlag check "--check"}"''${existing_zig_paths[@]}"
    fi
  '';
}
