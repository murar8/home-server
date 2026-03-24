{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    shellcheck.enable = true;
    shfmt.enable = true;
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
      strict = true;
    };
  };
}
