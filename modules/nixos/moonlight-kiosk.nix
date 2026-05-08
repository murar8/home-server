{ pkgs, ... }:

{
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
