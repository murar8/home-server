{ config, lib, ... }:

let
  # https://wiki.nixos.org/wiki/Systemd_Hardening
  sambaHardening = {
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    NoNewPrivileges = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    ProtectSystem = "full";
    ProtectHome = true;
  };
in
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

  systemd.tmpfiles.rules = [ "d /share 0755 ${config.local.user} users -" ];

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

  # https://wiki.nixos.org/wiki/Systemd_Hardening
  # sandbox samba: runs as root for auth but doesn't need kernel/hw access
  systemd.services = {
    samba-smbd.serviceConfig = sambaHardening;
    samba-nmbd.serviceConfig = sambaHardening;
  };
}
