{ config, lib, ... }:

let
  cfg = config.modules.initrd-ssh;
in

{
  options.modules.initrd-ssh = {
    user = lib.mkOption {
      type = lib.types.str;
      default = config.local.user;
      description = "User whose SSH authorized keys are used for initrd access.";
    };
    hostKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/etc/ssh/ssh_host_ed25519_key" ];
      description = "SSH host key paths for initrd SSH.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 2222;
      description = "SSH port during initrd.";
    };
    interface = lib.mkOption {
      type = lib.types.str;
      description = "Network interface for initrd networking.";
    };
    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Static IP addresses with prefix length (e.g. [\"192.168.1.60/24\"]).";
    };
    gateway = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Default gateways.";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = config.users.users.${cfg.user}.openssh.authorizedKeys.keys;
      description = "SSH public keys authorized during initrd.";
    };
  };

  config.boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        inherit (cfg) hostKeys port authorizedKeys;
      };
    };
    systemd = {
      users.root.shell = "/bin/systemd-tty-ask-password-agent";
      network = {
        enable = true;
        networks."10-${cfg.interface}" = {
          matchConfig.Name = cfg.interface;
          inherit (cfg) address gateway;
        };
      };
    };
  };
}
