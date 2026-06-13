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
}: {
  format-check = import ./format.nix {
    inherit pkgs src extraPackages formatDirs nixDirs;
  };

  code-check = import ./code.nix {
    inherit
      pkgs
      src
      extraPackages
      sourceDirs
      headerDirs
      headerIncludeFlags
      extraCmakeArgs
      extraHardeningFlags
      extraHardeningLinkerFlags
      buildDir
      ;
  };
}
