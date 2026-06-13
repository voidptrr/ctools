{
  pkgs,
  src,
  extraPackages ? [],
  formatDirs ? [],
  nixDirs ? [],
}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
  pkgs.runCommand "format-check" {
    nativeBuildInputs = with pkgs;
      [
        alejandra
        clang-tools
        findutils
      ]
      ++ extraPackages;
  } ''
    ${copySource}

    format_dirs=(${shellArgs formatDirs})
    nix_dirs=(${shellArgs nixDirs})

    if [ "''${#nix_dirs[@]}" -gt 0 ]; then
      alejandra --check "''${nix_dirs[@]}"
    fi

    find_existing_c_files() {
      for dir in "''${format_dirs[@]}"; do
        [ ! -d "$dir" ] || find "$dir" -type f \( -name '*.c' -o -name '*.h' \) -print0
      done
    }

    find_existing_c_files | xargs -0 --no-run-if-empty clang-format --dry-run --Werror
    touch "$out"
  ''
