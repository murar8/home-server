{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = "prodesk";
  local.net.ip = "192.168.1.130";

  imports = [
    ../../modules/base.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ./home-assistant.nix
    ./networking.nix
    ./samba.nix
    ./hardening.nix
  ];

  system.autoUpgrade = {
    enable = true;
    flake = "github:murar8/home-server#prodesk";
    flags = [
      "--recreate-lock-file"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };

  users.mutableUsers = false;
  users.users.${config.local.user}.hashedPasswordFile = "/persist/etc/secrets/user-password";

  programs.bash.interactiveShellInit = ''
    HISTFILE="/persist/home/$USER/.bash_history"
  '';

  environment = {
    systemPackages = with pkgs; [
      sbctl
      git
      nano
      neovim
      rsync
    ];

    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/secureboot"
        "/var/lib/nixos"
        "/var/lib/systemd/timers"
      ];
    };
  };

  # https://man.openbsd.org/ssh-keygen#DESCRIPTION
  # ed25519 only — smaller keys, faster, no known structural weaknesses
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  systemd.mounts = [
    {
      what = "tmpfs";
      where = "/var/tmp";
      type = "tmpfs";
      options = "mode=1777,nosuid,nodev,size=256M";
    }
  ];

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
          authorizedKeys = [ config.local.sshKey ];
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
          networks."10-${config.local.net.interface}" = {
            matchConfig.Name = config.local.net.interface;
            address = [ "${config.local.net.ip}/${toString config.local.net.prefixLength}" ];
            gateway = [ config.local.net.gateway ];
          };
        };
      };
    };
  };
}
