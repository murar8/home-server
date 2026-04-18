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

      # Lock all sessions when YubiKey is unplugged (YubiKey 5 series).
      # Scoped to the top-level USB device — HID/input sub-interfaces churn
      # during challenge-response (KeePassXC C/R) and would otherwise trigger
      # false-positive locks.
      # Match on ENV{PRODUCT} (vendor/product/bcd): 1050=Yubico, 0407=YubiKey 5 OTP+FIDO+CCID.
      # ID_MODEL_ID/ID_VENDOR_ID aren't repopulated on remove events, so we can't match on them.
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
