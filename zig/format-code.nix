{pkgs}:
import ../format-code.nix {
  inherit pkgs;
  enableC = false;
  enableZig = true;
}
