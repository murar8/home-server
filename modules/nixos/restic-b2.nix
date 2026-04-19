{ lib, pkgs, ... }:

# Backups to Backblaze B2 via restic.
# Secrets are TPM-sealed .cred files under /persist/etc/restic, generated
# once on-host (they bind to this machine's TPM + PCR 7, so they cannot
# be decrypted elsewhere and are safe to leave on disk).
#
# Bootstrap (run on prodesk, as root):
#
#   install -d -m 0700 /persist/etc/restic
#   systemd-creds encrypt --with-key=tpm2 --tpm2-pcrs=7 - \
#     /persist/etc/restic/repo-password.cred \
#     <<< "$(openssl rand -base64 32)"
#   systemd-creds encrypt --with-key=tpm2 --tpm2-pcrs=7 - \
#     /persist/etc/restic/b2-env.cred <<'EOF'
#   B2_ACCOUNT_ID=<application key id>
#   B2_ACCOUNT_KEY=<application key>
#   EOF
#
# Keep a copy of the repo password somewhere offline (Bitwarden) — losing
# it means the B2 backups are unrecoverable.

{
  users.users.restic = {
    isSystemUser = true;
    group = "restic";
  };
  users.groups.restic = { };

  security.wrappers.restic = {
    source = lib.getExe pkgs.restic;
    owner = "restic";
    group = "restic";
    permissions = "u+rx,g+rx,o=";
    capabilities = "cap_dac_read_search+ep";
  };

  environment.persistence."/persist".directories = [
    {
      directory = "/etc/restic";
      user = "root";
      group = "root";
      mode = "0700";
    }
  ];

  services.restic.backups.b2 = {
    initialize = true;
    repository = "b2:murar8-prodesk-restic:/";
    user = "restic";
    # EnvironmentFile= cannot read from systemd's credentials directory
    # (systemd issue #40333). Source B2 creds from the wrapper instead.
    # passwordFile becomes RESTIC_PASSWORD_FILE which restic reads at runtime,
    # so the credentials-dir path works there.
    package = pkgs.writeShellScriptBin "restic" ''
      set -a
      . "$CREDENTIALS_DIRECTORY/b2-env"
      set +a
      exec /run/wrappers/bin/restic "$@"
    '';
    passwordFile = "/run/credentials/restic-backups-b2.service/repo-password";
    paths = [ "/persist" ];
    exclude = [
      "/persist/var/lib/systemd/coredump"
      "/persist/var/lib/fwupd"
      "/persist/var/log"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
      "--keep-yearly 3"
    ];
  };

  systemd.services.restic-backups-b2.serviceConfig.LoadCredentialEncrypted = [
    "repo-password:/etc/restic/repo-password.cred"
    "b2-env:/etc/restic/b2-env.cred"
  ];
}
