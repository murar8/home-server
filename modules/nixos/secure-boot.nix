{ lib, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = lib.mkDefault "/var/lib/sbctl";
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
