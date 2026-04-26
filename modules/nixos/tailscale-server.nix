{ config, lib, ... }:

let
  # Subnet derivation assumes /24; assertion below guards against silent breakage.
  subnet = "${lib.concatStringsSep "." (lib.lists.init (lib.splitString "." config.local.net.gateway))}.0";
in
{
  assertions = [
    {
      assertion = config.local.net.prefixLength == 24;
      message = "tailscale-server: subnet derivation assumes /24, got /${toString config.local.net.prefixLength}.";
    }
  ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=${subnet}/${toString config.local.net.prefixLength}"
      "--advertise-exit-node"
    ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
