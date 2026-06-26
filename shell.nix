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
  extraPackages ? [],
  buildInputs ? [],
  nativeBuildInputs ? [],
  enableC ? false,
  enableZig ? false,
}: let
  lib = pkgs.lib;
  cPackages = with pkgs; [
    gcc
    cmake
    ninja
    clang-tools
  ];
  zigPackages = with pkgs; [
    zig
    zls
  ];
  defaultPackages =
    []
    ++ lib.optionals enableC cPackages
    ++ lib.optionals enableZig zigPackages;
in
  pkgs.mkShell {
    packages = defaultPackages ++ extraPackages;
    inherit buildInputs nativeBuildInputs;
  }
