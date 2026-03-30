{ config, lib, ... }:

let
  inherit (import ./vars.nix) vars;
  fqdn = "${vars.hostname}.${vars.tailnet}";
  syncthingGuiPort = lib.toInt (lib.last (lib.splitString ":" config.services.syncthing.guiAddress));
in
{
  networking = {
    hostName = vars.hostname;
    useDHCP = false;
    defaultGateway = vars.net.gateway;
    inherit (vars.net) nameservers;
    interfaces.${vars.net.interface} = {
      ipv4.addresses = [
        {
          address = vars.net.ip;
          inherit (vars.net) prefixLength;
        }
      ];
    };
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
      # restrict service ports to physical LAN only
      interfaces.${vars.net.interface}.allowedTCPPorts = [ syncthingGuiPort ];
    };
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      permitCertUid = "caddy";
      extraSetFlags = [
        "--advertise-routes=${vars.net.subnet}/${toString vars.net.prefixLength}"
        "--advertise-exit-node"
      ];
    };

    caddy = {
      enable = true;
      virtualHosts.${fqdn} = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString config.services.home-assistant.config.http.server_port}
        '';
      };
    };

    syncthing = {
      enable = true;
      inherit (vars) user;
      dataDir = "/home/${vars.user}";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
    };
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
      "/var/lib/caddy"
    ];
    users.${vars.user}.directories = [
      ".config/syncthing"
      "Documents"
    ];
  };

  # https://wiki.nixos.org/wiki/Systemd_Hardening
  # https://man7.org/linux/man-pages/man5/systemd.exec.5.html
  # sandbox caddy: only needs network + its state dir + tailscale socket (read-only)
  systemd.services.caddy.serviceConfig = vars.serviceHardening // {
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RestrictNamespaces = true;
    SystemCallArchitectures = "native";
    MemoryDenyWriteExecute = true;
    ReadWritePaths = [ "/var/lib/caddy" ];
  };
}
