{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    yubikey-manager # `ykman` CLI for PIV/OTP/FIDO2 management
    opensc # provides opensc-pkcs11.so loaded by Chrome/Firefox/AutoFirma for PIV client-cert auth
  ];

  environment.etc."u2f-mappings".text = "${config.local.user}:${config.local.u2fKeys}";

  # u2f globally enabled — disable for sshd (can't touch key remotely)
  security.pam.services.sshd.u2fAuth = false;

  services = {
    pcscd.enable = true;
    udev = {
      packages = [ pkgs.yubikey-personalization ];

      # Lock sessions on YubiKey 5 unplug. Match top-level usb_device only (sub-interfaces churn
      # during C/R). ENV{PRODUCT}=1050/407 (Yubico/YubiKey 5) — ID_* aren't set on remove events.
      extraRules = ''
        ACTION=="remove",\
         SUBSYSTEM=="usb",\
         ENV{DEVTYPE}=="usb_device",\
         ENV{PRODUCT}=="1050/407/*",\
         RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';
    };
  };

  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
      authfile = "/etc/u2f-mappings";
      origin = "pam://nixos";
      appid = "pam://nixos";
    };
  };
}
