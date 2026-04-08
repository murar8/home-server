{
  config,
  inputs,
  pkgs,
  ...
}:

{
  systemd.services.dotfiles-checkout = {
    description = "Checkout dotfiles into home directory";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # https://wiki.nixos.org/wiki/Systemd_Hardening
    serviceConfig = {
      Type = "oneshot";
      User = config.local.user;
      Group = "users";
      ProtectSystem = "strict";
      ReadWritePaths = [ "/home/${config.local.user}" ];
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
    script = builtins.readFile "${inputs.dotfiles}/.bootstrap";
  };
}
