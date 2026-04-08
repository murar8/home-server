{ config, lib, ... }:

{
  options.modules.initrd-ssh.hostKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "/etc/ssh/ssh_host_ed25519_key" ];
    description = "SSH host key paths for initrd SSH.";
  };

  config.assertions = [
    {
      assertion = config.boot.initrd.systemd.enable;
      message = "initrd-ssh requires systemd initrd.";
    }
  ];

  config.boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        inherit (config.modules.initrd-ssh) hostKeys;
        authorizedKeys = [ config.local.sshKey ];
      };
    };
    systemd = {
      users.root.shell = "/bin/systemd-tty-ask-password-agent";
      network = {
        enable = true;
        networks."10-${config.local.net.interface}" = {
          matchConfig.Name = config.local.net.interface;
          address = [ "${config.local.net.ip}/${toString config.local.net.prefixLength}" ];
          gateway = [ config.local.net.gateway ];
        };
      };
    };
  };
}
