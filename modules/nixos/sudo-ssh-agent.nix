{ config, lib, ... }:

{
  # Tap-to-sudo over forwarded SSH agent, via pam_rssh.
  # Two FIDO2 sk credentials on the YubiKey:
  #   - yubikeyLoginSshKey (no-touch-required) — silent SSH login
  #   - yubikeySudoSshKey  (touch-required)    — tap-to-sudo
  # Both resident on the same YubiKey; only the touch-required key is in the
  # sudo auth file, so pam_rssh always signs with that one.
  # Relies on the default 5-minute sudo cache — a longer timestamp_timeout
  # would defeat the point of tap-to-sudo.
  security = {
    pam.rssh = {
      enable = true;
      settings.auth_key_file = "/etc/ssh/sudo_authorized_keys.d/$user";
    };

    pam.services.sudo.rssh = true;

    # Intentional: pam_rssh needs the forwarded agent socket visible to sudo.
    # Security model assumes the forwarding client (Bitwarden agent on a trusted
    # workstation) is the only party that can sign challenges.
    sudo.extraConfig = lib.mkAfter ''
      Defaults env_keep+=SSH_AUTH_SOCK
    '';
  };

  environment.etc."ssh/sudo_authorized_keys.d/${config.local.user}".text =
    config.local.yubikeySudoSshKey;

  # sshd rejects sk-ssh-ed25519 signatures that lack the user-presence bit
  # unless the authorized_keys entry is prefixed with `no-touch-required`.
  users.users.${config.local.user}.openssh.authorizedKeys.keys = [
    "no-touch-required ${config.local.yubikeyLoginSshKey}"
  ];

  assertions = [
    {
      assertion = lib.hasPrefix "sk-ssh-ed25519" config.local.yubikeySudoSshKey;
      message = "local.yubikeySudoSshKey must be an ed25519-sk (FIDO2) key to enforce tap-to-sudo.";
    }
    {
      assertion = lib.hasPrefix "sk-ssh-ed25519" config.local.yubikeyLoginSshKey;
      message = "local.yubikeyLoginSshKey must be an ed25519-sk (FIDO2) key, created with -O no-touch-required.";
    }
  ];
}
