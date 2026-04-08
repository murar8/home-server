{ config, lib, ... }:

{
  networking.useNetworkd = true;
  networking.networkmanager.enable = false;

  systemd.network.networks."20-${config.local.net.interface}" = {
    matchConfig.Name = config.local.net.interface;
    address = lib.mkDefault [ "${config.local.net.ip}/${toString config.local.net.prefixLength}" ];
    gateway = lib.mkDefault [ config.local.net.gateway ];
  };
}
