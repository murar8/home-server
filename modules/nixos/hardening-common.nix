{ lib, ... }:

# Universal hardening — applied to every host via common.nix.
# Server-only additions (auditd, modprobe blacklist, martians, etc.) live in hardening.nix.
{
  # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  # prevent service accounts from accessing compilers and scripting languages via nix
  nix.settings.allowed-users = [ "@wheel" ];

  # https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  # only wheel users can execute the sudo binary, not just use it
  security.sudo.execWheelOnly = true;

  boot.kernel.sysctl = {
    # https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
    # ignore ICMP redirects to prevent MITM route table poisoning
    # (ipv4 .all already 0 via NixOS firewall)
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

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
    # allow reisub: keyboard (4) + signaling (64) + sync (16) + remount-ro (32) + reboot (128)
    # mkDefault so hosts can trim this down (e.g. headless server)
    "kernel.sysrq" = lib.mkDefault 244;
  };
}
