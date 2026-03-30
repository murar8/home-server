{
  dotfiles,
  pkgs,
  vars,
  ...
}:

{
  system.stateVersion = vars.stateVersion;

  time.timeZone = "Europe/Madrid";

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  users.users.${vars.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ vars.sshKey ];
  };

  programs.bash.loginShellInit = ''
    [ -f ~/.bashrc ] && . ~/.bashrc
  '';

  services = {
    btrfs.autoScrub.enable = true;

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
        # https://man.openbsd.org/sshd_config
        # prevent a compromised session from being used as a network tunnel
        AllowTcpForwarding = false;
        AllowStreamLocalForwarding = false;
        # https://man.openbsd.org/sshd_config#ClientAliveInterval
        # drop idle sessions after ~10 min (interval × countMax); does not affect initrd SSH
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };
  };

  systemd.services.dotfiles-checkout = {
    description = "Checkout dotfiles into home directory";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # https://wiki.nixos.org/wiki/Systemd_Hardening
    serviceConfig = {
      Type = "oneshot";
      User = vars.user;
      Group = "users";
      ProtectSystem = "strict";
      ReadWritePaths = [ "/home/${vars.user}" ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      PrivateDevices = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
    };
    path = with pkgs; [
      git
      openssh
    ];
    script = builtins.readFile "${dotfiles}/.bootstrap";
  };
}
