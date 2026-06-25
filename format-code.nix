{
  pkgs,
  enableC ? true,
  enableZig ? true,
}: let
  boolString = value:
    if value
    then "1"
    else "0";
in
  pkgs.writeShellApplication {
    name = "format-code";
    runtimeInputs = with pkgs; [
      alejandra
      clang-tools
      findutils
      zig
    ];
    text = ''
      enable_c=''${CTOOLS_ENABLE_C:-${boolString enableC}}
      enable_zig=''${CTOOLS_ENABLE_ZIG:-${boolString enableZig}}

      c_format_dirs_string=''${CTOOLS_C_FORMAT_DIRS:-"src tests include"}
      zig_format_dirs_string=''${CTOOLS_ZIG_FORMAT_DIRS:-"build.zig build.zig.zon src tests examples"}
      nix_dirs_string=''${CTOOLS_NIX_DIRS:-"."}

      read -r -a c_format_dirs <<< "$c_format_dirs_string"
      read -r -a zig_format_dirs <<< "$zig_format_dirs_string"
      read -r -a nix_dirs <<< "$nix_dirs_string"

      if [ "''${#nix_dirs[@]}" -gt 0 ]; then
        alejandra "''${nix_dirs[@]}"
      fi

      find_existing_c_files() {
        for dir in "''${c_format_dirs[@]}"; do
          [ ! -d "$dir" ] || find "$dir" -type f \( -name '*.c' -o -name '*.h' \) -print0
        done
      }

      append_existing_zig_paths() {
        for path in "''${zig_format_dirs[@]}"; do
          [ ! -e "$path" ] || existing_zig_paths+=("$path")
        done
      }

      if [ "$enable_c" = "1" ]; then
        find_existing_c_files | xargs -0 --no-run-if-empty clang-format -i
      fi

      if [ "$enable_zig" = "1" ]; then
        existing_zig_paths=()
        append_existing_zig_paths
        if [ "''${#existing_zig_paths[@]}" -gt 0 ]; then
          zig fmt "''${existing_zig_paths[@]}"
        fi
      fi
    '';
  }
