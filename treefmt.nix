{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    shellcheck.enable = true;
    shfmt.enable = true;
    prettier = {
      enable = true;
      includes = [ "*.hujson" ];
    };
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
      strict = true;
    };
  };
}
