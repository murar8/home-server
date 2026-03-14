{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    prettier.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
