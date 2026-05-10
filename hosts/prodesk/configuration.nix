{ config, flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.home-assistant
    flake.modules.nixos.impermanence
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.static-ip
    flake.modules.nixos.sudo-ssh-agent
    flake.modules.nixos.restic-b2
    flake.modules.nixos.healthchecks-runitor
    flake.modules.nixos.moonlight-kiosk
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.syncthing-server
    flake.modules.nixos.samba
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "prodesk";

  hardware.bluetooth.enable = true;
  # DS4/DualSense gamepad HID driver — udev modalias autoload doesn't fire
  # for BT-connected controllers, so load it eagerly
  boot.kernelModules = [ "hid_playstation" ];

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
    users.moonlight.directories = [
      ".config/Moonlight Game Streaming Project"
      ".local/state/wireplumber"
    ];
    directories = [
      "/var/lib/bluetooth"
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
