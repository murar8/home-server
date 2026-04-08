{ config, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:murar8/home-server#${config.networking.hostName}";
    flags = [
      "--recreate-lock-file"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };
}
