{ config, lib, ... }:

{
  assertions = [
    {
      assertion =
        lib.hasPrefix "192.168.1." config.local.net.gateway && config.local.net.prefixLength == 24;
      message = "samba: hardcoded \"hosts allow\" assumes 192.168.1.0/24, got ${config.local.net.gateway}/${toString config.local.net.prefixLength}.";
    }
  ];

  services = {
    samba = {
      enable = true;
      # https://www.samba.org/samba/docs/current/man-html/winbindd.8.html
      # winbindd maps Windows NT/AD users and groups to Unix — not needed with local-only auth
      winbindd.enable = false;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = config.networking.hostName;
          "netbios name" = config.networking.hostName;
          "security" = "user";
          "server min protocol" = "SMB3";
          "server smb encrypt" = "required";
          "hosts allow" = "192.168.1. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
        };
        share = {
          path = "/share";
          "valid users" = config.local.user;
          writable = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    samba-wsdd.enable = true;
  };

  systemd = {
    tmpfiles.rules = [ "d /share 0755 ${config.local.user} users -" ];

    # Sandboxes emitted by `shh service start-profile --mode aggressive`.
    services.samba-smbd.serviceConfig = {
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateDevices = true;
      PrivateMounts = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      RestrictRealtime = true;
      ProtectClock = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
        "AF_UNIX"
      ];
      SocketBindDeny = [
        "ipv4:udp"
        "ipv6:udp"
      ];
      CapabilityBoundingSet =
        "~"
        + lib.concatStringsSep " " [
          "CAP_BLOCK_SUSPEND"
          "CAP_BPF"
          "CAP_CHOWN"
          "CAP_IPC_LOCK"
          "CAP_MKNOD"
          "CAP_NET_RAW"
          "CAP_PERFMON"
          "CAP_SYS_BOOT"
          "CAP_SYS_CHROOT"
          "CAP_SYS_MODULE"
          "CAP_SYS_NICE"
          "CAP_SYS_PACCT"
          "CAP_SYS_PTRACE"
          "CAP_SYS_TIME"
          "CAP_SYSLOG"
          "CAP_WAKE_ALARM"
        ];
      SystemCallFilter =
        "~"
        + lib.concatStringsSep " " [
          "@aio:EPERM"
          "@chown:EPERM"
          "@clock:EPERM"
          "@cpu-emulation:EPERM"
          "@debug:EPERM"
          "@keyring:EPERM"
          "@memlock:EPERM"
          "@module:EPERM"
          "@mount:EPERM"
          "@obsolete:EPERM"
          "@pkey:EPERM"
          "@raw-io:EPERM"
          "@reboot:EPERM"
          "@resources:EPERM"
          "@sandbox:EPERM"
          "@swap:EPERM"
          "@sync:EPERM"
        ];
    };

    services.samba-nmbd.serviceConfig = {
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateTmp = "disconnected";
      PrivateDevices = true;
      PrivateMounts = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectProc = "ptraceable";
      LockPersonality = true;
      RestrictRealtime = true;
      ProtectClock = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_NETLINK"
        "AF_UNIX"
      ];
      SocketBindDeny = [
        "ipv4:tcp"
        "ipv6:tcp"
        "ipv6:udp"
      ];
      CapabilityBoundingSet =
        "~"
        + lib.concatStringsSep " " [
          "CAP_BLOCK_SUSPEND"
          "CAP_BPF"
          "CAP_CHOWN"
          "CAP_IPC_LOCK"
          "CAP_MKNOD"
          "CAP_NET_RAW"
          "CAP_PERFMON"
          "CAP_SYS_BOOT"
          "CAP_SYS_CHROOT"
          "CAP_SYS_MODULE"
          "CAP_SYS_NICE"
          "CAP_SYS_PACCT"
          "CAP_SYS_PTRACE"
          "CAP_SYS_TIME"
          "CAP_SYSLOG"
          "CAP_WAKE_ALARM"
        ];
      SystemCallFilter =
        "~"
        + lib.concatStringsSep " " [
          "@aio:EPERM"
          "@chown:EPERM"
          "@clock:EPERM"
          "@cpu-emulation:EPERM"
          "@debug:EPERM"
          "@keyring:EPERM"
          "@memlock:EPERM"
          "@module:EPERM"
          "@mount:EPERM"
          "@obsolete:EPERM"
          "@pkey:EPERM"
          "@privileged:EPERM"
          "@raw-io:EPERM"
          "@reboot:EPERM"
          "@resources:EPERM"
          "@sandbox:EPERM"
          "@setuid:EPERM"
          "@swap:EPERM"
          "@sync:EPERM"
          "@timer:EPERM"
        ];
    };
  };

  # LAN-only — not exposed on Tailscale
  networking.firewall.interfaces.${config.local.net.interface} = {
    allowedTCPPorts = [
      139
      445
    ];
    allowedUDPPorts = [
      137
      138
      3702
    ];
  };
}
