{ config, lib, ... }:

let
  fqdn = "${config.networking.hostName}.${config.local.tailnet}";
  syncthingGuiPort = lib.toInt (lib.last (lib.splitString ":" config.services.syncthing.guiAddress));
in
{
  networking = {
    useDHCP = false;
    defaultGateway = config.local.net.gateway;
    interfaces.${config.local.net.interface} = {
      ipv4.addresses = [
        {
          address = config.local.net.ip;
          inherit (config.local.net) prefixLength;
        }
      ];
    };
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
      # restrict service ports to physical LAN only
      interfaces.${config.local.net.interface}.allowedTCPPorts = [ syncthingGuiPort ];
    };
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      permitCertUid = "caddy";
      extraSetFlags = [
        "--advertise-routes=${config.local.net.subnet}/${toString config.local.net.prefixLength}"
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
      inherit (config.local) user;
      dataDir = "/home/${config.local.user}";
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
    };
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
      "/var/lib/caddy"
    ];
    users.${config.local.user}.directories = [
      ".config/syncthing"
      "Documents"
    ];
  };

  # https://wiki.nixos.org/wiki/Systemd_Hardening
  # https://man7.org/linux/man-pages/man5/systemd.exec.5.html
  # sandbox caddy: only needs network + its state dir + tailscale socket (read-only)
  systemd.services.caddy.serviceConfig = {
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    NoNewPrivileges = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
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
