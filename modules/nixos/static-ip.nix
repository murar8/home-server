{ config, ... }:

{
  networking = {
    useDHCP = false;
    defaultGateway = config.local.net.gateway;
    interfaces.${config.local.net.interface}.ipv4.addresses = [
      {
        address = config.local.net.ip;
        inherit (config.local.net) prefixLength;
      }
    ];
  };
}
