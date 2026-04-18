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

    yubikeySudoSshKey = lib.mkOption {
      description = "FIDO2 ed25519-sk SSH public key (touch-required) — authorized for tap-to-sudo.";
      type = lib.types.str;
      default = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE2lA+l6+B7WSc/MTVHCKM1k0nx8829f6lmBiu56QLLrAAAAC3NzaDpwcm9kZXNr yubikey-prodesk-sudo";
    };

    yubikeyLoginSshKey = lib.mkOption {
      description = "FIDO2 ed25519-sk SSH public key (no-touch-required) — authorized for silent SSH login.";
      type = lib.types.str;
      default = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIC70g/4Y1ZAR5wZxsWwSSZ8FqmySBvoPewV8tCSixng8AAAAEXNzaDpwcm9kZXNrLWxvZ2lu yubikey-prodesk-login";
    };

    u2fKeys = lib.mkOption {
      description = "FIDO2 U2F key mappings for pam_u2f (output of pamu2fcfg).";
      type = lib.types.str;
      default = "AxptVFSc5KEG28YJwkCsFbDFwZ4hTZlBLkKUUtmWUl02LuyEZ+Oy2wX8LB9fn2Prfjjm4gdO4I9jRX7N9qBnbA==,UotHID4MD06WMhk3OcMjjuXD4wxvuVAQgLekeshY+8EbCbtPJy4vlb5M7pBv4IqUijktq4N3jf/FeA2xkuxmCg==,es256,+presence";
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
