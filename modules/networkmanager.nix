{ config, ... }:

{
  networking.networkmanager.enable = true;
  users.users.${config.local.user}.extraGroups = [ "networkmanager" ];
}
