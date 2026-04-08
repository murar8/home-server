{ config, ... }:

{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=${config.local.user}" ];
  };
}
