{ pkgs, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/nvidia.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  programs.gamemode.enable = true;

  environment.systemPackages = [ (pkgs.heroic.override { extraPkgs = pkgs': [ pkgs'.gamemode ]; }) ];

  networking = {
    hostName = "debian";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };

  boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCfqnufJrf3pZxXvFcqbB1vUhyc0EFuDBuUEO7Q0Luq lnzmrr@gmail.com"
        ];
      };
    };
    systemd = {
      users.root.shell = "/bin/systemd-tty-ask-password-agent";
      network = {
        enable = true;
        networks."10-enp5s0" = {
          matchConfig.Name = "enp5s0";
          address = [ "192.168.1.60/24" ];
          gateway = [ "192.168.1.1" ];
        };
      };
    };
  };
}
