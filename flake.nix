{
  description = "shared C project tooling";

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
      mkCShell = import ./shell.nix;
      mkCChecks = import ./checks;
    };

    formatter = forEachSystem ({pkgs}: pkgs.alejandra);

    devShells = forEachSystem ({pkgs}: {
      default = self.lib.mkCShell {inherit pkgs;};
    });

    checks = forEachSystem ({pkgs}: let
      checks = self.lib.mkCChecks {
        inherit pkgs;
        src = self;
        nixDirs = ["flake.nix" "shell.nix" "checks"];
      };
    in {
      inherit (checks) format-check;
    });
  };
}
