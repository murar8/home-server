_:

{
  services.openssh = {
    enable = true;
    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # disable SFTP subsystem — unused, removes a code-exec surface inside sshd
    allowSFTP = false;
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
      # SSH-7408 (lynis): more forensic detail on auth attempts.
      LogLevel = "VERBOSE";
      # SSH-7408: cap pre-auth attempts per connection.
      MaxAuthTries = 3;
      # SSH-7408: limit concurrent sessions / multiplexed channels.
      MaxSessions = 2;
      # SSH-7408: ClientAlive* already provides authenticated keepalives;
      # disable the unauthenticated TCP-level ones to shut a small spoof window.
      TCPKeepAlive = false;
    };
  };
}
