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
  sambaHardening = {
    ProtectSystem = "full";
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    NoNewPrivileges = true;
    LockPersonality = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./home-assistant.nix
  ];

  system.stateVersion = "24.11";

  systemd = {
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

    services = {
      # https://wiki.nixos.org/wiki/Systemd_Hardening
      # https://man7.org/linux/man-pages/man5/systemd.exec.5.html
      # sandbox caddy: only needs network + its state dir + tailscale socket (read-only)
      caddy.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ "/var/lib/caddy" ];
      };

      # https://wiki.nixos.org/wiki/Systemd_Hardening
      # sandbox samba: runs as root for auth but doesn't need kernel/hw access
      samba-smbd.serviceConfig = sambaHardening;
      samba-nmbd.serviceConfig = sambaHardening;
    };
  };

  boot = {
    tmp = {
      useTmpfs = true;
      tmpfsSize = "256M";
    };
    # https://madaidans-insecurities.github.io/guides/linux-hardening.html#kernel-modules
    # prevent loading unused network protocols and filesystems (common local exploit targets)
    extraModprobeConfig = ''
      install dccp /bin/false
      install sctp /bin/false
      install rds /bin/false
      install tipc /bin/false
      install cramfs /bin/false
      install freevxfs /bin/false
      install hfs /bin/false
      install hfsplus /bin/false
      install jffs2 /bin/false
      install udf /bin/false
    '';
    kernel.sysctl = {
      # https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
      # don't send ICMP redirects — Tailscale subnet routing enables IP forwarding,
      # but LAN hosts should use their own gateway, not be redirected through us
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      # ignore ICMP redirects to prevent MITM route table poisoning
      # (ipv4 .all already 0 via NixOS firewall)
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      # log packets with impossible source addresses for forensic investigation
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;

      # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/kernel.rst
      # hide kernel pointers from /proc even for root — mitigates info leaks for local exploits
      "kernel.kptr_restrict" = 2;
      # https://www.kernel.org/doc/Documentation/admin-guide/LSM/Yama.rst
      # restrict ptrace to parent→child only — blocks debugger-based privilege escalation
      "kernel.yama.ptrace_scope" = 1;
      # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/kernel.rst
      # prevent unprivileged users from loading BPF programs (local privesc vector)
      "kernel.unprivileged_bpf_disabled" = 1;
      # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/net.rst
      # harden BPF JIT for all users to prevent JIT spraying attacks
      "net.core.bpf_jit_harden" = 2;
      # https://www.kernel.org/doc/Documentation/admin-guide/sysrq.rst
      # allow only sync (16) + remount-ro (32) + reboot (128) for emergency recovery
      "kernel.sysrq" = 176;
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
    options = "--delete-older-than 7d";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # prevent service accounts from accessing compilers and scripting languages via nix
    allowed-users = [ "@wheel" ];
    auto-optimise-store = true;
  };

  environment = {
    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # replace default packages (nano, perl, rsync, strace) with explicit list
    defaultPackages = lib.mkForce [ ];

    systemPackages = with pkgs; [
      sbctl
      git
      nano
      neovim
    ];
  };

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

    # https://www.samba.org/samba/docs/current/man-html/winbindd.8.html
    # winbindd maps Windows NT/AD users and groups to Unix — not needed with local-only auth
    samba.winbindd.enable = false;

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

  security = {
    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # https://man7.org/linux/man-pages/man8/auditd.8.html
    # log every program execution for intrusion detection
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };

    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # only wheel users can execute the sudo binary, not just use it
    sudo.execWheelOnly = true;
  };

  users.mutableUsers = false;

  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = "/persist/etc/secrets/user-password";
    openssh.authorizedKeys.keys = [ vars.ssh.key ];
  };
}
