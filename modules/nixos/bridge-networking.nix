{ config, ... }:

let
  bridgeName = "br0";
in
{
  assertions = [
    {
      assertion = config.networking.useNetworkd;
      message = "bridge-networking requires systemd-networkd (networking.useNetworkd).";
    }
  ];

  systemd.network = {
    links."20-${config.local.net.interface}" = {
      matchConfig.OriginalName = config.local.net.interface;
      linkConfig.WakeOnLan = "magic";
    };
    netdevs."20-${bridgeName}".netdevConfig = {
      Name = bridgeName;
      Kind = "bridge";
    };
    networks = {
      "20-${config.local.net.interface}" = {
        matchConfig.Name = config.local.net.interface;
        networkConfig.Bridge = bridgeName;
        # Override static-ip defaults — address/gateway move to the bridge
        address = [ ];
        gateway = [ ];
      };
      "20-${bridgeName}" = {
        matchConfig.Name = bridgeName;
        address = [ "${config.local.net.ip}/${toString config.local.net.prefixLength}" ];
        gateway = [ config.local.net.gateway ];
      };
    };
  };
}
