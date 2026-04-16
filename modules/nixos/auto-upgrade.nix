{ config, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:murar8/home-server#${config.networking.hostName}";
    flags = [ "-L" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };
}
