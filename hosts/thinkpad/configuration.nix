{ config, ... }:

{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop
    ../../modules/desktop/gnome
    ../../modules/desktop/fprintd.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  users.users.${config.local.user}.extraGroups = [ "networkmanager" ];
}
