{
  lib,
  pkgs,
  dotfiles,
  ...
}:

let
  inherit (import ./vars.nix) vars;
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./home-assistant.nix
    ./networking.nix
    ./samba.nix
    ./hardening.nix
  ];

  system.stateVersion = "24.11";

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  users.mutableUsers = false;

  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = "/persist/etc/secrets/user-password";
    openssh.authorizedKeys.keys = [ vars.ssh.key ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      git
      nano
      neovim
    ];

    persistence."/persist" = {
      hideMounts = true;
      users.${vars.user}.files = [ ".bash_history" ];
      directories = [
        "/etc/secureboot"
        "/var/lib/nixos"
        "/var/lib/systemd/timers"
      ];
    };
  };

  services = {
    btrfs.autoScrub.enable = true;

    openssh = {
      enable = true;
      # https://man.openbsd.org/ssh-keygen#DESCRIPTION
      # ed25519 only — smaller keys, faster, no known structural weaknesses
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
        # https://man.openbsd.org/sshd_config
        # prevent a compromised session from being used as a network tunnel
        AllowTcpForwarding = false;
        AllowAgentForwarding = false;
        AllowStreamLocalForwarding = false;
        # https://man.openbsd.org/sshd_config#ClientAliveInterval
        # drop idle sessions after ~10 min (interval × countMax); does not affect initrd SSH
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };
  };

  systemd = {
    mounts = [
      {
        what = "tmpfs";
        where = "/var/tmp";
        type = "tmpfs";
        options = "mode=1777,nosuid,nodev,size=256M";
      }
    ];

    services.dotfiles-checkout = {
      description = "Checkout dotfiles into home directory";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      before = [ "sshd.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = vars.user;
        Group = "users";
        # https://wiki.nixos.org/wiki/Systemd_Hardening
        ProtectSystem = "strict";
        ReadWritePaths = [ "/home/${vars.user}" ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        PrivateDevices = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
      };
      path = with pkgs; [
        git
        openssh
      ];
      script = builtins.readFile "${dotfiles}/.bootstrap";
    };
  };

  boot = {
    tmp = {
      useTmpfs = true;
      tmpfsSize = "256M";
    };
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    initrd = {
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
    };
  };
}
