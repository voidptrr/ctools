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
  src ? ./.,
  extraPackages ? [],
  buildInputs ? [],
  nativeBuildInputs ? [],
  enableC ? null,
  enableZig ? builtins.pathExists (src + "/build.zig"),
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
  effectiveEnableC =
    if enableC == null
    then builtins.pathExists (src + "/CMakeLists.txt") || hasCFiles
    else enableC;
  format-code = import ./format-code.nix {inherit pkgs;};
  cPackages = with pkgs; [
    gcc
    cmake
    ninja
    clang-tools
  ];
  zigPackages = with pkgs; [
    zig
  ];
  defaultPackages =
    [
      pkgs.alejandra
      format-code
    ]
    ++ lib.optionals effectiveEnableC cPackages
    ++ lib.optionals enableZig zigPackages;
in
  pkgs.mkShell {
    packages = defaultPackages ++ extraPackages;
    inherit buildInputs nativeBuildInputs;
  }
