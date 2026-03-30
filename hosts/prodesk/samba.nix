_:

let
  inherit (import ./vars.nix) vars;
  sambaHardening = vars.serviceHardening // {
    ProtectSystem = "full";
    ProtectHome = true;
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

  environment.persistence."/persist".directories = [ "/var/lib/samba" ];

  systemd.tmpfiles.rules = [ "d /share 0755 ${vars.user} users -" ];

  # LAN-only — not exposed on Tailscale
  networking.firewall.interfaces.${vars.net.interface} = {
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
