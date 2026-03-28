{ pkgs, ... }:

{
  programs.gamemode.enable = true;

  environment.systemPackages = [ (pkgs.heroic.override { extraPkgs = pkgs': [ pkgs'.gamemode ]; }) ];
}
