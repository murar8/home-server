{ vars, ... }:

{
  imports = [
    ../../modules/desktop.nix
    ../../modules/gnome.nix
    ../../modules/fprintd.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  users.users.${vars.user}.extraGroups = [ "networkmanager" ];
}
