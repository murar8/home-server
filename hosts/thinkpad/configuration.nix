_:

{
  imports = [
    ../../modules/common.nix
    ../../modules/gnome.nix
    ../../modules/fprintd.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking = {
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  users.users.murar8.extraGroups = [ "networkmanager" ];
}
