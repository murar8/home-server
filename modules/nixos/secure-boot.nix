{ lib, pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = lib.mkDefault "/var/lib/sbctl";
    autoGenerateKeys.enable = lib.mkDefault true;
    autoEnrollKeys.enable = lib.mkDefault true;
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
