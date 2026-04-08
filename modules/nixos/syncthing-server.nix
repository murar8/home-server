{ config, ... }:

let
  guiPort = 8384;
in
{
  services.syncthing = {
    enable = true;
    inherit (config.local) user;
    dataDir = "/home/${config.local.user}";
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:${toString guiPort}";
  };

  # restrict GUI to physical LAN only
  networking.firewall.interfaces.${config.local.net.interface}.allowedTCPPorts = [ guiPort ];

  environment.persistence."/persist".users.${config.local.user}.directories = [
    ".config/syncthing"
    "Documents"
  ];
}
