{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    prettier = {
      enable = true;
      includes = [ "*.hujson" ];
    };
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
