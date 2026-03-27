# Fingerprint authentication with GDM workaround
# https://github.com/NixOS/nixpkgs/issues/171136
# https://wiki.nixos.org/wiki/Fingerprint_scanner
# fprintd disables password login in GDM without this workaround
{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.fprintd.enable = true;

  security.pam.services.login.fprintAuth = false;
  security.pam.services.gdm-fingerprint = lib.mkIf config.services.fprintd.enable {
    text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
      auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
      session    optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
    '';
  };
}
