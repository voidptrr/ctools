{
  pkgs,
  extraPackages ? [],
  buildInputs ? [],
  nativeBuildInputs ? [],
}: let
  format-code = import ./format-code.nix {inherit pkgs;};
  defaultPackages = with pkgs; [
    alejandra
    format-code
    zig
  ];
in
  pkgs.mkShell {
    packages = defaultPackages ++ extraPackages;
    inherit buildInputs nativeBuildInputs;
  }
