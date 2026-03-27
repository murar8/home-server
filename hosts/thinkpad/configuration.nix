_:

{
  imports = [
    ../../modules/common.nix
    ../../modules/fprintd.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "thinkpad";
}
