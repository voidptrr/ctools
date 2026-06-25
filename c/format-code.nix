{pkgs}:
import ../format-code.nix {
  inherit pkgs;
  enableC = true;
  enableZig = false;
}
