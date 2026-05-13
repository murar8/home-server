{ pkgs, ... }:

let
  tvEdidFirmware = pkgs.runCommand "tv-edid-firmware" { } ''
    install -Dm444 ${./tv-edid.bin} $out/lib/firmware/edid/tv.bin
  '';
in
{
  # Force HDMI connector active even with TV off, so gamescope finds a CRTC at
  # boot. The injected EDID (captured from the TV) makes the connector
  # advertise 1080p instead of the kernel's VESA fallback list (max 1024x768).
  # Pairs with the TV's "auto power on when signal detected" setting.
  boot.kernelParams = [
    "video=HDMI-A-2:1920x1080@60e"
    "drm.edid_firmware=HDMI-A-2:edid/tv.bin"
  ];
  hardware.firmware = [ tvEdidFirmware ];

  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  users.users.moonlight = {
    isNormalUser = true;
    description = "Moonlight kiosk";
    extraGroups = [ "input" ];
  };

  services = {
    udev.extraRules = ''
      ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
      KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", GROUP="input", MODE="0660"
      KERNEL=="hidraw*", KERNELS=="*054C:09CC*", GROUP="input", MODE="0660"
      SUBSYSTEM=="sound", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", ENV{ACP_IGNORE}="1", ENV{PULSE_IGNORE}="1"
    '';
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f -- ${pkgs.moonlight-qt}/bin/moonlight";
        user = "moonlight";
      };
    };
  };
}
