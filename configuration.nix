{
  lib,
  pkgs,
  config,
  dotfiles,
  ...
}:

let
  inherit (import ./vars.nix) vars;
  fqdn = "${vars.hostname}.${vars.tailnet}";
  syncthingGuiPort = lib.toInt (lib.last (lib.splitString ":" config.services.syncthing.guiAddress));
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./home-assistant.nix
  ];

  system.stateVersion = "24.11";

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "256M";
  };

  systemd = {
    services.dotfiles-checkout = {
      description = "Checkout dotfiles into home directory";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = vars.user;
        Group = "users";
      };
      path = with pkgs; [
        git
        openssh
      ];
      script = builtins.readFile "${dotfiles}/.bootstrap";
    };

    tmpfiles.rules = [
      "d /share 0755 ${vars.user} users -"
    ];

    mounts = [
      {
        what = "tmpfs";
        where = "/var/tmp";
        type = "tmpfs";
        options = "mode=1777,nosuid,nodev,size=256M";
      }
    ];
  };

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
        services.rollback = {
          description = "Rollback btrfs root to a blank snapshot";
          wantedBy = [ "initrd.target" ];
          after = [ "systemd-cryptsetup@cryptroot.service" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = builtins.readFile ./rollback.sh;
        };
        network = {
          enable = true;
          networks."10-${vars.net.interface}" = {
            matchConfig.Name = vars.net.interface;
            address = [ "${vars.net.ip}/${toString vars.net.prefixLength}" ];
            gateway = [ vars.net.gateway ];
          };
        };
      };
      availableKernelModules = [ "r8169" ];
      supportedFilesystems = [ "btrfs" ];
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = [ vars.ssh.key ];
        };
      };
    };
  };

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  networking = {
    hostName = vars.hostname;
    useDHCP = false;
    defaultGateway = vars.net.gateway;
    inherit (vars.net) nameservers;
    interfaces.${vars.net.interface} = {
      ipv4.addresses = [
        {
          address = vars.net.ip;
          inherit (vars.net) prefixLength;
        }
      ];
    };
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [
        config.services.home-assistant.config.http.server_port
        syncthingGuiPort
      ];
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/secureboot"
      "/var/lib/nixos"
      "/var/lib/systemd/timers"
      "/var/lib/tailscale"
      "/var/lib/hass"
      "/var/lib/caddy"
      "/var/lib/samba"
    ];
    users.${vars.user}.directories = [
      ".config/syncthing"
      "Documents"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  environment.systemPackages = with pkgs; [
    sbctl
    git
    neovim
  ];

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      permitCertUid = "caddy";
      extraSetFlags = [
        "--advertise-routes=${vars.net.subnet}/${toString vars.net.prefixLength}"
        "--advertise-exit-node"
      ];
    };

    caddy = {
      enable = true;
      virtualHosts.${fqdn} = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.home-assistant.config.http.server_port}
        '';
      };
    };

    syncthing = {
      enable = true;
      inherit (vars) user;
      dataDir = "/home/${vars.user}";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
    };

    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = vars.hostname;
          "netbios name" = vars.hostname;
          "security" = "user";
          "server min protocol" = "SMB3";
          "server smb encrypt" = "required";
          "hosts allow" = "${vars.net.subnetPrefix} 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
        };
        share = {
          path = "/share";
          "valid users" = vars.user;
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    btrfs.autoScrub.enable = true;

    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  users.mutableUsers = false;

  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = "/persist/etc/secrets/user-password";
    openssh.authorizedKeys.keys = [ vars.ssh.key ];
  };
}
