{ config, ... }:

{
  services.syncthing = {
    enable = true;
    inherit (config.local) user;
    dataDir = "/home/${config.local.user}";
    openDefaultPorts = true;
    systemService = false;
  };
}
