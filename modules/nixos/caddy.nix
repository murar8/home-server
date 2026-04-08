_: {
  environment.persistence."/persist".directories = [ "/var/lib/caddy" ];

  services.caddy.enable = true;

  # https://wiki.nixos.org/wiki/Systemd_Hardening
  # https://man7.org/linux/man-pages/man5/systemd.exec.5.html
  # sandbox caddy: only needs network + its state dir + tailscale socket (read-only)
  systemd.services.caddy.serviceConfig = {
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
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RestrictNamespaces = true;
    SystemCallArchitectures = "native";
    MemoryDenyWriteExecute = true;
    ReadWritePaths = [ "/var/lib/caddy" ];
  };
}
