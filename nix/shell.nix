{
  pkgs,
  extraPackages ? [],
}: let
  defaultPackages = with pkgs; [
    gcc
    cmake
    ninja
    clang-tools
    alejandra
  ];
in
  pkgs.mkShell {
    packages = defaultPackages ++ extraPackages;
  }
