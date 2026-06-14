# MIT License
#
# Copyright (c) 2026 Tommaso Bruno
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
{
  pkgs,
  src,
  extraPackages ? [],
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
      "-O1" # Enables _FORTIFY_SOURCE checks while keeping sanitizer stacks readable.
      "-g3" # Emits full debug info so sanitizer and test failures point at useful source locations.
      "-fno-omit-frame-pointer" # Preserves frame pointers for reliable sanitizer backtraces.
      "-fstack-protector-strong" # Adds stack canaries to functions with likely stack-smashing risk.
      "-D_FORTIFY_SOURCE=3" # Adds compile-time and runtime bounds checks for supported libc calls.
      "-fPIE" # Builds position-independent objects required for a PIE executable.
      "-fsanitize=address,undefined" # Instruments memory-safety and undefined-behavior checks.
    ]
    ++ extraHardeningFlags;
  hardeningLinkerFlags =
    [
      "-Wl,-z,relro,-z,now" # Makes relocation tables read-only and resolves symbols at startup.
      "-pie" # Links the executable as position-independent so ASLR can randomize it fully.
      "-fsanitize=address,undefined" # Links the sanitizer runtimes required by the instrumentation.
    ]
    ++ extraHardeningLinkerFlags;

  shellArgs = values: lib.escapeShellArgs values;
  headerSearchDirs = lib.unique (sourceDirs ++ headerDirs);
  effectiveHeaderIncludeFlags =
    headerIncludeFlags
    ++ map (dir: "-I${dir}") headerSearchDirs;

  copySource = ''
    cp -R --no-preserve=mode,ownership ${src} source
    cd source
  '';
in
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
    header_include_flags=(${shellArgs effectiveHeaderIncludeFlags})
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

    while IFS= read -r -d "" file; do
      run_clang_tidy "$file" -- "''${header_include_flags[@]}"
    done < <(
      for dir in "''${source_dirs[@]}" "''${header_dirs[@]}"; do
        [ ! -d "$dir" ] || find "$dir" -type f -name '*.h' -print0
      done | sort -zu
    )

    ctest --test-dir ${lib.escapeShellArg buildDir} --output-on-failure
    touch "$out"
  ''
