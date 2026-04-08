{ flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.hardening
    flake.modules.nixos.home-assistant
    flake.modules.nixos.impermanence
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.static-ip
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.syncthing-server
    flake.modules.nixos.samba
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "prodesk";
  local.net.ip = "192.168.1.130";
  local.net.interface = "enp1s0";

  boot.initrd.availableKernelModules = [ "r8169" ];
  modules.initrd-ssh.hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];

}
