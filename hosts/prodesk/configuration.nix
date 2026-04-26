{ config, flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.hardening
    flake.modules.nixos.home-assistant
    flake.modules.nixos.impermanence
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.static-ip
    flake.modules.nixos.sudo-ssh-agent
    flake.modules.nixos.restic-b2
    flake.modules.nixos.healthchecks-runitor
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.syncthing-server
    flake.modules.nixos.samba
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "prodesk";

  boot.initrd.availableKernelModules = [ "r8169" ];
  modules.initrd-ssh.hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];

  local = {
    net.ip = "192.168.1.130";
    net.interface = "enp1s0";
    restic = {
      paths = [ "/persist" ];
      exclude = [
        "/persist/home/murar8/Documents"
        "/persist/var/lib/fwupd"
        "/persist/var/lib/systemd/coredump"
        "/persist/var/log"
      ];
    };
  };

  environment.persistence."/persist" = {
    users.${config.local.user}.directories = [
      ".config/syncthing"
      "Documents"
    ];
    directories = [
      "/var/lib/hass"
      "/var/lib/samba"
      "/var/lib/tailscale"
      {
        directory = "/etc/healthchecks";
        user = "root";
        group = "root";
        mode = "0700";
      }
      {
        directory = "/etc/restic";
        user = "root";
        group = "root";
        mode = "0700";
      }
    ];
  };
}
