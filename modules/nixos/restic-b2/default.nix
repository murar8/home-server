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

    security.wrappers.restic = {
      source = lib.getExe pkgs.restic;
      owner = "restic";
      group = "restic";
      permissions = "u+rx,g+rx,o=";
      capabilities = "cap_dac_read_search+ep";
    };

    services.restic.backups.b2 = {
      initialize = true;
      repository = "b2:murar8-${config.networking.hostName}-restic:/";
      user = "restic";
      package = pkgs.writeShellApplication {
        name = "restic";
        runtimeInputs = [ pkgs.coreutils ];
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

    systemd.services.restic-backups-b2.serviceConfig.LoadCredentialEncrypted = [
      "repo-password:/etc/restic/repo-password.cred"
      "b2-account-id:/etc/restic/b2-account-id.cred"
      "b2-account-key:/etc/restic/b2-account-key.cred"
    ];
  };
}
