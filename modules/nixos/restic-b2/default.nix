{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.local.restic = lib.mkOption {
    description = "Restic B2 backup paths and excludes (bucket derived from hostname).";
    default = { };
    type = lib.types.submodule {
      options = {
        paths = lib.mkOption {
          description = "Paths to back up.";
          type = lib.types.listOf lib.types.str;
          default = [ "/home/${config.local.user}" ];
        };
        exclude = lib.mkOption {
          description = "Paths and patterns to exclude from backup.";
          type = lib.types.listOf lib.types.str;
          default =
            let
              home = "/home/${config.local.user}";
            in
            [
              "${home}/.cache"
              "${home}/.cargo/git"
              "${home}/.cargo/registry"
              "${home}/.config/Cypress"
              "${home}/.config/Slack"
              "${home}/.config/google-chrome/*/Cache"
              "${home}/.config/google-chrome/*/Code Cache"
              "${home}/.config/google-chrome/*/GPUCache"
              "${home}/.dotfiles"
              "${home}/.local/share/Steam"
              "${home}/.local/share/Trash"
              "${home}/.local/share/nvim"
              "${home}/.local/share/umu"
              "${home}/.local/share/virtualenv"
              "${home}/.npm"
              "${home}/.platformio"
              "${home}/.yarn"
              "${home}/Documents"
              "${home}/Downloads"
            ];
        };
      };
    };
  };

  config = {
    users.users.restic = {
      isSystemUser = true;
      group = "restic";
    };
    users.groups.restic = { };

    systemd.tmpfiles.rules = [ "d /etc/restic 0700 root root -" ];

    services.restic.backups.b2 = {
      initialize = true;
      repository = "b2:murar8-${config.networking.hostName}-restic:/";
      user = "restic";
      package = pkgs.writeShellApplication {
        name = "restic";
        runtimeInputs = [ pkgs.restic ];
        text = builtins.readFile ./restic-wrapper.sh;
      };
      passwordFile = "/run/credentials/restic-backups-b2.service/repo-password";
      inherit (config.local.restic) paths exclude;
      extraBackupArgs = [ "--exclude-caches" ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
    };

    systemd.services.restic-backups-b2.serviceConfig = {
      LoadCredentialEncrypted = [
        "repo-password:/etc/restic/repo-password.cred"
        "b2-account-id:/etc/restic/b2-account-id.cred"
        "b2-account-key:/etc/restic/b2-account-key.cred"
      ];
      AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];

      # Sandbox: emitted by `shh run --mode aggressive` against a real /persist
      # backup (resolver panics inside the systemd service wrapper, so this was
      # captured outside the unit). CapabilityBoundingSet is tightened to the
      # ambient cap allow-list since the unit runs as a non-root user.
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
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
        "AF_NETLINK"
        "AF_UNIX"
      ];
      SocketBindDeny = [
        "ipv4:tcp"
        "ipv4:udp"
        "ipv6:tcp"
        "ipv6:udp"
      ];
      SystemCallFilter =
        "~"
        + lib.concatStringsSep " " [
          "@aio:EPERM"
          "@chown:EPERM"
          "@clock:EPERM"
          "@cpu-emulation:EPERM"
          "@debug:EPERM"
          "@ipc:EPERM"
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
}
