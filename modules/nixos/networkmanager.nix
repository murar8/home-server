{ config, ... }:

{
  networking.networkmanager = {
    enable = true;
    # Keep NM out of /etc/resolv.conf so networking.nameservers (base.nix) wins.
    dns = "none";
    ensureProfiles.profiles.lan-static = {
      connection = {
        id = "lan-static";
        type = "ethernet";
        interface-name = config.local.net.interface;
        autoconnect = true;
        autoconnect-priority = 100;
      };
      ipv4 = {
        method = "manual";
        addresses = "${config.local.net.ip}/${toString config.local.net.prefixLength}";
        inherit (config.local.net) gateway;
      };
    };
  };
  users.users.${config.local.user}.extraGroups = [ "networkmanager" ];
}
