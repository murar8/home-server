{ config, lib, ... }:

let
  cfg = config.modules.initrd-ssh;
  persistPrefixes = lib.attrNames (config.environment.persistence or { });
  sshdKeys = map (k: k.path) config.services.openssh.hostKeys;
  isPersisted = key: lib.any (p: lib.hasPrefix p key) persistPrefixes;
in
{
  options.modules.initrd-ssh.hostKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    description = "Ed25519 SSH host key paths for initrd SSH.";
  };

  config = {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "initrd-ssh requires systemd initrd.";
      }
      {
        assertion = persistPrefixes == [ ] || lib.all isPersisted cfg.hostKeys;
        message = "initrd-ssh host keys must be under a persistence mount on impermanence hosts.";
      }
      {
        assertion = lib.all (key: !lib.elem key sshdKeys) cfg.hostKeys;
        message = "initrd-ssh host keys must not reuse the main sshd host keys (exposes them on unencrypted /boot).";
      }
    ];

    boot.initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          inherit (cfg) hostKeys;
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
  };
}
