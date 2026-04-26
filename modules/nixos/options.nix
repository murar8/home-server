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
