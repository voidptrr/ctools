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
  pkgs.runCommand "zig-format-check" {
    nativeBuildInputs = with pkgs;
      [
        alejandra
        zig
      ]
      ++ extraPackages;
  } ''
    ${copySource}

    format_dirs=(${shellArgs formatDirs})
    nix_dirs=(${shellArgs nixDirs})

    if [ "''${#nix_dirs[@]}" -gt 0 ]; then
      alejandra --check "''${nix_dirs[@]}"
    fi

    append_existing_zig_paths() {
      for path in "''${format_dirs[@]}"; do
        [ ! -e "$path" ] || existing_zig_paths+=("$path")
      done
    }

    existing_zig_paths=()
    append_existing_zig_paths
    if [ "''${#existing_zig_paths[@]}" -gt 0 ]; then
      zig fmt --check "''${existing_zig_paths[@]}"
    fi
    touch "$out"
  ''
