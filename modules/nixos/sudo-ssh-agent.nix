{ config, lib, ... }:

{
  options.local = {
    yubikeySudoSshKey = lib.mkOption {
      description = "FIDO2 ed25519-sk SSH public key (touch-required) — authorized for tap-to-sudo.";
      type = lib.types.str;
      default = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE2lA+l6+B7WSc/MTVHCKM1k0nx8829f6lmBiu56QLLrAAAAC3NzaDpwcm9kZXNr yubikey-prodesk-sudo";
    };

    yubikeyLoginSshKey = lib.mkOption {
      description = "FIDO2 ed25519-sk SSH public key (no-touch-required) — authorized for silent SSH login.";
      type = lib.types.str;
      default = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIC70g/4Y1ZAR5wZxsWwSSZ8FqmySBvoPewV8tCSixng8AAAAEXNzaDpwcm9kZXNrLWxvZ2lu yubikey-prodesk-login";
    };
  };

  config = {
    security = {
      pam.rssh = {
        enable = true;
        settings.auth_key_file = "/etc/ssh/sudo_authorized_keys.d/$user";
      };

      pam.services.sudo.rssh = true;

      # pam_rssh needs the forwarded agent socket visible to sudo.
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
  };
}
