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
  extraCmakeArgs ? [],
  extraHardeningFlags ? [],
  extraHardeningLinkerFlags ? [],
  buildDir ? "build/hardened",
  enableCTest ? true,
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
in
  pkgs.runCommand "c-test-check" {
    nativeBuildInputs = with pkgs;
      [
        cmake
        gcc
        ninja
      ]
      ++ extraPackages;
  } ''
    ${copySource}

    cmake_args=(${shellArgs cmakeArgs})

    rm -rf ${lib.escapeShellArg buildDir}

    cmake \
      -S . \
      -B ${lib.escapeShellArg buildDir} \
      -G Ninja \
      -DCMAKE_C_FLAGS=${lib.escapeShellArg (shellArgs hardeningFlags)} \
      -DCMAKE_EXE_LINKER_FLAGS=${lib.escapeShellArg (shellArgs hardeningLinkerFlags)} \
      "''${cmake_args[@]}"

    cmake --build ${lib.escapeShellArg buildDir}

    ${
      if enableCTest
      then "ctest --test-dir ${lib.escapeShellArg buildDir} --output-on-failure"
      else "true"
    }

    touch "$out"
  ''
