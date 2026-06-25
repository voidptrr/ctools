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
  description = "shared C and Zig project tooling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forEachSystem = f:
      nixpkgs.lib.genAttrs systems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    lib = {
      mkShell = import ./shell.nix;
      mkChecks = import ./checks;
      mkCShell = import ./c/shell.nix;
      mkCChecks = import ./c;
      mkZigShell = import ./zig/shell.nix;
      mkZigChecks = import ./zig;
      mkZigCChecks = import ./zig/c.nix;
    };

    formatter = forEachSystem ({pkgs}: pkgs.alejandra);

    packages = forEachSystem ({pkgs}: let
      format-code = import ./format-code.nix {inherit pkgs;};
      c-format-code = import ./c/format-code.nix {inherit pkgs;};
      zig-format-code = import ./zig/format-code.nix {inherit pkgs;};
    in {
      inherit format-code c-format-code zig-format-code;
      default = format-code;
    });

    devShells = forEachSystem ({pkgs}: {
      default = self.lib.mkShell {
        inherit pkgs;
        enableC = true;
        enableZig = true;
      };
    });

    checks = forEachSystem ({pkgs}: let
      checks = self.lib.mkCChecks {
        inherit pkgs;
        src = self;
        nixDirs = ["flake.nix" "shell.nix" "format-code.nix" "checks" "c" "zig"];
      };
    in {
      inherit (checks) format-check;
    });
  };
}
