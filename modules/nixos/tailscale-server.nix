{ config, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    permitCertUid = "caddy";
    extraSetFlags = [
      "--advertise-routes=${config.local.net.subnet}/${toString config.local.net.prefixLength}"
      "--advertise-exit-node"
    ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  environment.persistence."/persist".directories = [ "/var/lib/tailscale" ];
}
