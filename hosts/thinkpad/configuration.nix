{ flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.desktop
    flake.modules.nixos.docker
    flake.modules.nixos.gnome
    flake.modules.nixos.keyd
    flake.modules.nixos.restic-b2
    flake.modules.nixos.tailscale-client
    flake.modules.nixos.syncthing-client
    flake.modules.nixos.fprintd
    flake.modules.nixos.networkmanager
    flake.modules.nixos.yubikey
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "thinkpad";
}
