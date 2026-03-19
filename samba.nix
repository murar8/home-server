_:

let
  inherit (import ./vars.nix) vars;
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
  services = {
    samba = {
      enable = true;
      # https://www.samba.org/samba/docs/current/man-html/winbindd.8.html
      # winbindd maps Windows NT/AD users and groups to Unix — not needed with local-only auth
      winbindd.enable = false;
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
    };
  };

  # https://wiki.nixos.org/wiki/Systemd_Hardening
  # sandbox samba: runs as root for auth but doesn't need kernel/hw access
  systemd.services = {
    samba-smbd.serviceConfig = sambaHardening;
    samba-nmbd.serviceConfig = sambaHardening;
  };
}
