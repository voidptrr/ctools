{
  pkgs,
  src,
  extraPackages ? [],
  lintDirs ? [],
}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
  pkgs.runCommand "zig-lint-check" {
    nativeBuildInputs = with pkgs;
      [
        findutils
        zig
      ]
      ++ extraPackages;
  } ''
    ${copySource}

    lint_dirs=(${shellArgs lintDirs})

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache"

    find_existing_zig_files() {
      for path in "''${lint_dirs[@]}"; do
        if [ -d "$path" ]; then
          find "$path" -type f -name '*.zig' -print0
        elif [ -f "$path" ]; then
          case "$path" in
            *.zig) printf '%s\0' "$path" ;;
          esac
        fi
      done
    }

    find_existing_zig_files | xargs -0 --no-run-if-empty zig ast-check
    touch "$out"
  ''
