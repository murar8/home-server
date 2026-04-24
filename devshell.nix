{
  pkgs,
  flake,
  system,
  ...
}:

pkgs.mkShell {
  inherit (flake.checks.${system}.git-hooks) shellHook;
  packages = with pkgs; [
    statix
    nil
    opentofu
  ];
}
