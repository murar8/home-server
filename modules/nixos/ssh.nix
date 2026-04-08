_:

{
  services.openssh = {
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
}
