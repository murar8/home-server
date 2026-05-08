{
  config,
  lib,
  pkgs,
  ...
}:

let
  host = config.networking.hostName;
  loadKey = [ "ping-key:/etc/healthchecks/ping-key.cred" ];
  restic = config.services.restic.backups ? b2;

  # Sandbox: emitted by `shh service start-profile --mode aggressive`. Shared
  # by all hc-* units; smart-check drops PrivateDevices since smartctl needs
  # raw device IO. Regenerate via shh when a unit's behavior changes.
  sandbox = {
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = "disconnected";
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
  };

  sandboxWithDevices = sandbox // {
    PrivateDevices = true;
  };
in
{
  systemd = {
    tmpfiles.rules = [ "d /etc/healthchecks 0700 root root -" ];

    services = {
      # Half-hourly: systemd not degraded. Doubles as liveness — no ping when box is down.
      hc-system-check = {
        path = [
          pkgs.runitor
          pkgs.systemd
        ];
        serviceConfig = sandboxWithDevices // {
          Type = "oneshot";
          LoadCredentialEncrypted = loadKey;
        };
        script = ''
          runitor -ping-key file:$CREDENTIALS_DIRECTORY/ping-key -slug ${host}-system -- \
            systemctl is-system-running --quiet
        '';
      };

      # Daily: /, /persist, /nix below 85%.
      hc-disk-check = {
        path = [
          pkgs.runitor
          pkgs.bash
          pkgs.coreutils
          pkgs.util-linux
        ];
        serviceConfig = sandboxWithDevices // {
          Type = "oneshot";
          LoadCredentialEncrypted = loadKey;
        };
        script = ''
          runitor -ping-key file:$CREDENTIALS_DIRECTORY/ping-key -slug ${host}-disk -- \
            bash -c '
              for m in / /persist /nix; do
                mountpoint -q "$m" || continue
                pcent="$(df --output=pcent "$m" | tail -n1 | tr -dc 0-9)"
                if [ "$pcent" -ge 85 ]; then echo "$m at $pcent%"; exit 1; fi
              done
            '
        '';
      };

      # Daily: smartctl -H on every autodetected disk. PrivateDevices off — smartctl needs raw IO.
      hc-smart-check = {
        path = [
          pkgs.runitor
          pkgs.bash
          pkgs.smartmontools
        ];
        serviceConfig = sandbox // {
          Type = "oneshot";
          LoadCredentialEncrypted = loadKey;
        };
        script = ''
          runitor -ping-key file:$CREDENTIALS_DIRECTORY/ping-key -slug ${host}-smart -- \
            bash -c '
              rc=0
              # smartctl --scan emits e.g. "/dev/sda -d sat # comment"; strip the
              # comment and word-split the rest so -d <type> reaches smartctl.
              while read -r line; do
                line="''${line%%#*}"
                [ -z "''${line// }" ] && continue
                # shellcheck disable=SC2086
                smartctl -H $line || rc=1
              done < <(smartctl --scan)
              exit "$rc"
            '
        '';
      };

      # Restic is managed by services.restic so we can't wrap its ExecStart.
      # Instead, fire ping-only units on success/failure. Slug = instance name (%i).
      "hc-success@" = lib.mkIf restic {
        path = [ pkgs.runitor ];
        serviceConfig = sandboxWithDevices // {
          Type = "oneshot";
          DynamicUser = true;
          LoadCredentialEncrypted = loadKey;
        };
        scriptArgs = "%i";
        script = ''runitor -ping-key file:$CREDENTIALS_DIRECTORY/ping-key -slug "$1" -- true'';
      };
      "hc-fail@" = lib.mkIf restic {
        path = [
          pkgs.runitor
          pkgs.systemd
        ];
        # Sandbox profile carried over from hc-success@ — re-running shh on
        # hc-fail@ requires a real failure to trace, so the profile may drift
        # if the script changes meaningfully. Verified working as-is.
        serviceConfig = sandboxWithDevices // {
          Type = "oneshot";
          DynamicUser = true;
          # Read journal of the unit that triggered us via OnFailure=.
          SupplementaryGroups = [ "systemd-journal" ];
          LoadCredentialEncrypted = loadKey;
        };
        scriptArgs = "%i";
        # systemd sets MONITOR_UNIT for OnFailure=-triggered units. Pipe its
        # journal to runitor so the HC body shows why the source unit failed.
        # `-on-success fail` redirects the success ping to /fail, so runitor
        # exits 0 even though we want the check marked failing.
        script = ''
          journalctl -u "$MONITOR_UNIT" -n 100 --no-pager | \
            runitor -on-success fail -ping-key file:$CREDENTIALS_DIRECTORY/ping-key -slug "$1" -- cat
        '';
      };
      restic-backups-b2 = lib.mkIf restic {
        unitConfig = {
          OnSuccess = "hc-success@${host}-restic.service";
          OnFailure = "hc-fail@${host}-restic.service";
        };
      };
    };

    timers = {
      hc-system-check = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "30min";
          RandomizedDelaySec = "2min";
          Persistent = true;
        };
      };
      hc-disk-check = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "30min";
          Persistent = true;
        };
      };
      hc-smart-check = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "30min";
          Persistent = true;
        };
      };
    };
  };
}
