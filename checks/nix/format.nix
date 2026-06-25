{
  pkgs,
  src,
  extraPackages ? [],
  nixDirs ? [],
}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
  pkgs.runCommand "nix-format-check" {
    nativeBuildInputs = [pkgs.alejandra] ++ extraPackages;
  } ''
    ${copySource}

    nix_dirs=(${shellArgs nixDirs})

    if [ "''${#nix_dirs[@]}" -gt 0 ]; then
      alejandra --check "''${nix_dirs[@]}"
    fi

    touch "$out"
  ''
