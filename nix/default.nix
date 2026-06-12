{self ? null}: {
  mkCShell = import ./shell.nix;
  mkCChecks = import ./checks.nix;
}
