{
  pkgs,
  extraPackages ? [],
  buildInputs ? [],
  nativeBuildInputs ? [],
}: let
  format-code = import ./packages/format-code.nix {inherit pkgs;};
  defaultPackages = with pkgs; [
    gcc
    cmake
    ninja
    clang-tools
    alejandra
    format-code
  ];
in
  pkgs.mkShell {
    packages = defaultPackages ++ extraPackages;
    inherit buildInputs nativeBuildInputs;
  }
