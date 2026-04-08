{ config, inputs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];
  assertions = [
    {
      assertion = config.boot.initrd.systemd.enable;
      message = "Impermanence module requires systemd initrd for the rollback service.";
    }
  ];

  users.mutableUsers = false;
  users.users.${config.local.user}.hashedPasswordFile = "/persist/etc/secrets/user-password";

  programs.bash.interactiveShellInit = ''
    HISTFILE="/persist/home/$USER/.bash_history"
  '';

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/secureboot"
      "/var/lib/nixos"
      "/var/lib/systemd/timers"
    ];
  };

  # https://man.openbsd.org/ssh-keygen#DESCRIPTION
  # ed25519 only — smaller keys, faster, no known structural weaknesses
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  systemd.mounts = [
    {
      what = "tmpfs";
      where = "/var/tmp";
      type = "tmpfs";
      options = "mode=1777,nosuid,nodev,size=256M";
    }
  ];

  boot.lanzaboote.pkiBundle = "/etc/secureboot";

  boot = {
    initrd.supportedFilesystems = [ "btrfs" ];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "256M";
    };
    initrd.systemd.services.rollback = {
      description = "Rollback btrfs root to a blank snapshot";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@cryptroot.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = builtins.readFile ./rollback.sh;
    };
  };
}
