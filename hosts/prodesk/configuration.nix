{ inputs, flake, ... }:

{
  networking.hostName = "prodesk";
  local.net.ip = "192.168.1.130";
  local.net.interface = "enp1s0";

  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.base
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.hardening
    flake.modules.nixos.home-assistant
    flake.modules.nixos.impermanence
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.networking
    flake.modules.nixos.samba
    flake.modules.nixos.secure-boot
    inputs.impermanence.nixosModules.impermanence
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "r8169" ];
  modules.initrd-ssh.hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];

}
