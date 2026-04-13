{ lib, ... }:

# Server-only hardening — opted into by hosts that want the strict profile.
# Universal settings (nix users, sudo wheel, kernel sysctls) live in hardening-common.nix.
{
  # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  # replace default packages (nano, perl, rsync, strace) with explicit list
  environment.defaultPackages = lib.mkForce [ ];

  security = {
    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # https://man7.org/linux/man-pages/man8/auditd.8.html
    # log every program execution for intrusion detection
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };
  };

  # https://madaidans-insecurities.github.io/guides/linux-hardening.html#kernel-modules
  # prevent loading unused network protocols and filesystems (common local exploit targets)
  boot.extraModprobeConfig = ''
    install dccp /bin/false
    install sctp /bin/false
    install rds /bin/false
    install tipc /bin/false
    install cramfs /bin/false
    install freevxfs /bin/false
    install hfs /bin/false
    install hfsplus /bin/false
    install jffs2 /bin/false
    install udf /bin/false
  '';

  boot.kernel.sysctl = {
    # https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
    # don't send ICMP redirects — Tailscale subnet routing enables IP forwarding,
    # but LAN hosts should use their own gateway, not be redirected through us
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # log packets with impossible source addresses for forensic investigation
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # https://www.kernel.org/doc/Documentation/admin-guide/sysrq.rst
    # override hardening-common default: only sync (16) + remount-ro (32) + reboot (128)
    # — no keyboard/signaling; reisub not needed on headless server
    "kernel.sysrq" = 176;
  };
}
