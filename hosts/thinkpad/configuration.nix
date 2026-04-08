{ flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.desktop
    flake.modules.nixos.docker
    flake.modules.nixos.gnome
    flake.modules.nixos.keyd
    flake.modules.nixos.tailscale-client
    flake.modules.nixos.syncthing-client
    flake.modules.nixos.fprintd
    flake.modules.nixos.networkmanager
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "thinkpad";
}
