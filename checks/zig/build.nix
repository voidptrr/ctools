{
  pkgs,
  src,
  extraPackages ? [],
  zigBuildArgs ? [],
  extraZigBuildArgs ? [],
}: let
  lib = pkgs.lib;
  shellArgs = values: lib.escapeShellArgs values;
  effectiveZigBuildArgs = zigBuildArgs ++ extraZigBuildArgs;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
  pkgs.runCommand "zig-build-check" {
    nativeBuildInputs = [pkgs.zig] ++ extraPackages;
  } ''
    ${copySource}

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache"

    zig build \
      --cache-dir "$ZIG_LOCAL_CACHE_DIR" \
      --global-cache-dir "$ZIG_GLOBAL_CACHE_DIR" \
      ${shellArgs effectiveZigBuildArgs}

    touch "$out"
  ''
