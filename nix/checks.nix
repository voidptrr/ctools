{
  pkgs,
  src,
  extraPackages ? [],
  formatDirs ? [],
  nixDirs ? [],
  sourceDirs ? [],
  headerDirs ? [],
  headerIncludeFlags ? [],
  extraCmakeArgs ? [],
  extraHardeningFlags ? [],
  extraHardeningLinkerFlags ? [],
  buildDir ? "build/hardened",
}: let
  lib = pkgs.lib;

  cmakeArgs = extraCmakeArgs;
  hardeningFlags =
    [
      "-O1"
      "-g3"
      "-fno-omit-frame-pointer"
      "-fstack-protector-strong"
      "-D_FORTIFY_SOURCE=3"
      "-fPIE"
      "-fsanitize=address,undefined"
    ]
    ++ extraHardeningFlags;
  hardeningLinkerFlags =
    [
      "-Wl,-z,relro,-z,now"
      "-pie"
      "-fsanitize=address,undefined"
    ]
    ++ extraHardeningLinkerFlags;

  shellArgs = values: lib.escapeShellArgs values;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in {
  format-check =
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
    '';

  code-check =
    pkgs.runCommand "code-check" {
      nativeBuildInputs = with pkgs;
        [
          clang-tools
          cmake
          findutils
          gcc
          ninja
        ]
        ++ extraPackages;
    } ''
      ${copySource}

      source_dirs=(${shellArgs sourceDirs})
      header_dirs=(${shellArgs headerDirs})
      header_include_flags=(${shellArgs headerIncludeFlags})
      cmake_args=(${shellArgs cmakeArgs})

      rm -rf ${lib.escapeShellArg buildDir}

      cmake \
        -S . \
        -B ${lib.escapeShellArg buildDir} \
        -G Ninja \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCMAKE_C_FLAGS=${lib.escapeShellArg (shellArgs hardeningFlags)} \
        -DCMAKE_EXE_LINKER_FLAGS=${lib.escapeShellArg (shellArgs hardeningLinkerFlags)} \
        "''${cmake_args[@]}"

      cmake --build ${lib.escapeShellArg buildDir}

      filter_clang_tidy_output() {
        sed \
          -e '/^[0-9][0-9]* warnings generated\.$/d' \
          -e '/^Suppressed [0-9][0-9]* warnings/d' \
          -e '/^Use -header-filter=/d'
      }

      run_clang_tidy() {
        status=0
        output="$(clang-tidy --quiet "$@" 2>&1)" || status=$?
        output="$(printf '%s\n' "$output" | filter_clang_tidy_output)"
        if [ -n "$output" ]; then
          printf '%s\n' "$output"
          exit 1
        fi
        [ "$status" -eq 0 ] || exit "$status"
      }

      for dir in "''${source_dirs[@]}"; do
        [ ! -d "$dir" ] || while IFS= read -r file; do
          run_clang_tidy -p ${lib.escapeShellArg buildDir} "$file"
        done < <(find "$dir" -type f -name '*.c')
      done

      for dir in "''${header_dirs[@]}"; do
        [ ! -d "$dir" ] || while IFS= read -r file; do
          run_clang_tidy "$file" -- "''${header_include_flags[@]}"
        done < <(find "$dir" -type f -name '*.h')
      done

      ctest --test-dir ${lib.escapeShellArg buildDir} --output-on-failure
      touch "$out"
    '';
}
