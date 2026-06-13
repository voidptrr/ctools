{pkgs}:
pkgs.writeShellApplication {
  name = "format-code";
  runtimeInputs = with pkgs; [
    alejandra
    clang-tools
    findutils
  ];
  text = ''
    format_dirs_string=''${CTOOLS_FORMAT_DIRS:-"src tests include"}
    nix_dirs_string=''${CTOOLS_NIX_DIRS:-"."}

    read -r -a format_dirs <<< "$format_dirs_string"
    read -r -a nix_dirs <<< "$nix_dirs_string"

    if [ "''${#nix_dirs[@]}" -gt 0 ]; then
      alejandra "''${nix_dirs[@]}"
    fi

    find_existing_c_files() {
      for dir in "''${format_dirs[@]}"; do
        [ ! -d "$dir" ] || find "$dir" -type f \( -name '*.c' -o -name '*.h' \) -print0
      done
    }

    find_existing_c_files | xargs -0 --no-run-if-empty clang-format -i
  '';
}
