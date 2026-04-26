{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd = {
    tmpfiles.rules = [ "d /etc/healthchecks 0700 root root -" ];

    services.healthchecks-heartbeat = {
      description = "Healthchecks.io heartbeat ping via runitor";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        PrivateUsers = true;
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        LoadCredentialEncrypted = [ "ping-key:/etc/healthchecks/ping-key.cred" ];
        Environment = [ "HC_SLUG=${config.networking.hostName}-heartbeat" ];
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "healthchecks-heartbeat";
            runtimeInputs = [
              pkgs.runitor
              pkgs.coreutils
            ];
            text = builtins.readFile ./heartbeat.sh;
          }
        );
      };
    };

    timers.healthchecks-heartbeat = {
      description = "Healthchecks.io heartbeat ping schedule";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        RandomizedDelaySec = "1min";
        Persistent = true;
      };
    };
  };
}
