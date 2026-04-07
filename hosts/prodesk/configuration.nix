_:

{
  networking.hostName = "prodesk";
  local.net.ip = "192.168.1.130";
  local.net.interface = "enp1s0";

  imports = [
    ../../modules/base.nix
    ../../modules/auto-upgrade.nix
    ../../modules/hardening.nix
    ../../modules/home-assistant
    ../../modules/impermanence
    ../../modules/boot/initrd-ssh.nix
    ../../modules/networking.nix
    ../../modules/samba.nix
    ../../modules/secure-boot.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "r8169" ];
  modules.initrd-ssh.hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];

}
