{ lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  system.stateVersion = "24.11";

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    initrd = {
      systemd = {
        enable = true;
        users.root.shell = "/bin/systemd-tty-ask-password-agent";
        network = {
          enable = true;
          networks."10-enp1s0" = {
            matchConfig.Name = "enp1s0";
            address = [ "192.168.1.130/24" ];
            gateway = [ "192.168.1.1" ];
            networkConfig.DHCP = "no";
          };
        };
      };
      availableKernelModules = [ "r8169" ];
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPaCgI6vuTA++m49TSmiQco2Pk/RggMp6W6AQaAEwqUj lorenzo@worldofv.art"
          ];
        };
      };
    };
  };

  networking = {
    hostName = "server";
    useDHCP = false;
    defaultGateway = "192.168.1.1";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "192.168.1.130";
          prefixLength = 24;
        }
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [ pkgs.sbctl ];

  services.btrfs.autoScrub.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.murar8 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPaCgI6vuTA++m49TSmiQco2Pk/RggMp6W6AQaAEwqUj lorenzo@worldofv.art"
    ];
  };
}
