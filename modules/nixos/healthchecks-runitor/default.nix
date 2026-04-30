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
        LoadCredentialEncrypted = [ "ping-key:/etc/healthchecks/ping-key.cred" ];

        # Sandbox: emitted by `shh service start-profile --mode aggressive`.
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = "disconnected";
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
          "ipv4:tcp"
          "ipv4:udp"
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
            "CAP_KILL"
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
            "CAP_SYS_TTY_CONFIG"
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
