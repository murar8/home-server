{ lib, ... }:

{
  options.local = {
    user = lib.mkOption {
      description = "Primary user account name.";
      type = lib.types.str;
      default = "murar8";
    };

    sshKey = lib.mkOption {
      description = "SSH public key for the primary user.";
      type = lib.types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCfqnufJrf3pZxXvFcqbB1vUhyc0EFuDBuUEO7Q0Luq lnzmrr@gmail.com";
    };

    stateVersion = lib.mkOption {
      description = "NixOS state version.";
      type = lib.types.str;
      default = "25.11";
    };

    timeZone = lib.mkOption {
      description = "System time zone.";
      type = lib.types.str;
      default = "Europe/Madrid";
    };

    locale = lib.mkOption {
      description = "Default system locale.";
      type = lib.types.str;
      default = "es_ES.UTF-8";
    };

    keyMap = lib.mkOption {
      description = "Console and X keyboard layout.";
      type = lib.types.str;
      default = "us";
    };

    supportedLocales = lib.mkOption {
      description = "Supported locale definitions.";
      type = lib.types.listOf lib.types.str;
      default = [
        "es_ES.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };

    nameservers = lib.mkOption {
      description = "DNS nameservers.";
      type = lib.types.listOf lib.types.str;
      default = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };

    tailnet = lib.mkOption {
      description = "Tailscale tailnet domain.";
      type = lib.types.str;
      default = "tail87795f.ts.net";
    };

    net = lib.mkOption {
      description = "Static network configuration.";
      type = lib.types.submodule {
        options = {
          ip = lib.mkOption {
            description = "Static IP address.";
            type = lib.types.str;
          };
          prefixLength = lib.mkOption {
            description = "Network prefix length.";
            type = lib.types.int;
            default = 24;
          };
          subnet = lib.mkOption {
            description = "Subnet address.";
            type = lib.types.str;
            default = "192.168.1.0";
          };
          subnetPrefix = lib.mkOption {
            description = "Subnet prefix for host matching (e.g. \"192.168.1.\").";
            type = lib.types.str;
            default = "192.168.1.";
          };
          gateway = lib.mkOption {
            description = "Default gateway.";
            type = lib.types.str;
            default = "192.168.1.1";
          };
          interface = lib.mkOption {
            description = "Network interface name.";
            type = lib.types.str;
          };
        };
      };
    };
  };
}
