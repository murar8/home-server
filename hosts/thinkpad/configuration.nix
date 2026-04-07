_:

{
  imports = [
    ../../modules/base.nix
    ../../modules/desktop
    ../../modules/desktop/gnome
    ../../modules/desktop/fprintd.nix
    ../../modules/networkmanager.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "thinkpad";
}
