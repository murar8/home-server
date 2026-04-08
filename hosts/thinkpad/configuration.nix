{ flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.desktop
    flake.modules.nixos.gnome
    flake.modules.nixos.fprintd
    flake.modules.nixos.networkmanager
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "thinkpad";
}
