{ lib, ... }:

{
  # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  # prevent service accounts from accessing compilers and scripting languages via nix
  nix.settings.allowed-users = [ "@wheel" ];

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

    # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
    # only wheel users can execute the sudo binary, not just use it
    sudo.execWheelOnly = true;
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
    # ignore ICMP redirects to prevent MITM route table poisoning
    # (ipv4 .all already 0 via NixOS firewall)
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # log packets with impossible source addresses for forensic investigation
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/kernel.rst
    # hide kernel pointers from /proc even for root — mitigates info leaks for local exploits
    "kernel.kptr_restrict" = 2;
    # https://www.kernel.org/doc/Documentation/admin-guide/LSM/Yama.rst
    # restrict ptrace to parent→child only — blocks debugger-based privilege escalation
    "kernel.yama.ptrace_scope" = 1;
    # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/kernel.rst
    # prevent unprivileged users from loading BPF programs (local privesc vector)
    "kernel.unprivileged_bpf_disabled" = 1;
    # https://www.kernel.org/doc/Documentation/admin-guide/sysctl/net.rst
    # harden BPF JIT for all users to prevent JIT spraying attacks
    "net.core.bpf_jit_harden" = 2;
    # https://www.kernel.org/doc/Documentation/admin-guide/sysrq.rst
    # allow only sync (16) + remount-ro (32) + reboot (128) for emergency recovery
    "kernel.sysrq" = 176;
  };
}
