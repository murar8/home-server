{ config, lib, ... }:

let
  cfg = config.modules.bridge-networking;
in
{
  options.modules.bridge-networking.name = lib.mkOption {
    type = lib.types.str;
    default = "br0";
    description = "Bridge interface name.";
  };

  config = {
    networking.useNetworkd = true;

    systemd.network = {
      links."20-${config.local.net.interface}" = {
        matchConfig.OriginalName = config.local.net.interface;
        linkConfig.WakeOnLan = "magic";
      };
      netdevs."20-${cfg.name}".netdevConfig = {
        Name = cfg.name;
        Kind = "bridge";
      };
      networks = {
        "20-${config.local.net.interface}" = {
          matchConfig.Name = config.local.net.interface;
          networkConfig.Bridge = cfg.name;
        };
        "20-${cfg.name}" = {
          matchConfig.Name = cfg.name;
          address = [ "${config.local.net.ip}/${toString config.local.net.prefixLength}" ];
          gateway = [ config.local.net.gateway ];
        };
      };
    };
  };
}
