{
  config,
  lib,
  pkgs,
  ...
}:

{
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
    package = pkgs.writeShellScriptBin "restic" ''
      B2_ACCOUNT_ID="$(cat "$CREDENTIALS_DIRECTORY/b2-account-id")"
      B2_ACCOUNT_KEY="$(cat "$CREDENTIALS_DIRECTORY/b2-account-key")"
      export B2_ACCOUNT_ID B2_ACCOUNT_KEY
      exec /run/wrappers/bin/restic "$@"
    '';
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
}
