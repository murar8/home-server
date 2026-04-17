{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.yubikey-manager ];

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
      extraRules = ''
        ACTION=="remove",\
         SUBSYSTEM=="usb",\
         ENV{DEVTYPE}=="usb_device",\
         ENV{ID_BUS}=="usb",\
         ENV{ID_MODEL_ID}=="0407",\
         ENV{ID_VENDOR_ID}=="1050",\
         ENV{ID_VENDOR}=="Yubico",\
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
