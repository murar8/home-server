{ config, flake, ... }:

{
  imports = [
    flake.modules.nixos.common
    flake.modules.nixos.auto-upgrade
    flake.modules.nixos.caddy
    flake.modules.nixos.hardening
    flake.modules.nixos.home-assistant
    flake.modules.nixos.impermanence
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.static-ip
    flake.modules.nixos.sudo-ssh-agent
    flake.modules.nixos.restic-b2
    flake.modules.nixos.tailscale-server
    flake.modules.nixos.syncthing-server
    flake.modules.nixos.samba
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "prodesk";
  local.net.ip = "192.168.1.130";
  local.net.interface = "enp1s0";

  # Wire home-assistant to caddy reverse proxy
  services.caddy.virtualHosts."prodesk.${config.local.tailnet}".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.home-assistant.config.http.server_port}
  '';

  boot.initrd.availableKernelModules = [ "r8169" ];
  modules.initrd-ssh.hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];

}
