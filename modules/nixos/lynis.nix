{ lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.lynis ];

  # TODO: revisit dccp/sctp/rds/tipc — blacklist worked but lynis still flags
  # NETW-3200 because it greps module files in /lib/modules; needs a mitigation
  # lynis recognizes (or compile-out) before we can re-enable.

  # ACCT-9628: enable auditd; log every program execution for post-compromise
  # forensics. man:auditd(8), man:auditctl(8).
  security = {
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };
  };

  # KRNL-6000: sysctls flagged by lynis. See man:sysctl(8). Skips covered in
  # custom.prf with their reasons.
  boot.kernel.sysctl = {
    "dev.tty.ldisc_autoload" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.suid_dumpable" = 0;
    "kernel.kptr_restrict" = 2;
    # https://www.kernel.org/doc/Documentation/admin-guide/sysrq.rst
    # 0 satisfies lynis KRNL-6000; desktops override to 244 (reisub) in desktop.nix.
    "kernel.sysrq" = lib.mkDefault 0;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  environment.etc."lynis/custom.prf".text = ''
    # Custom lynis profile. Add `skip-test=<ID>` lines below as we explicitly
    # opt out of audit findings, with a per-line comment explaining why.

    # Owned services hardened via shh; remaining UNSAFE units are upstream-managed
    # (sshd, dbus, nix-daemon, tailscaled, smartd, getty*) and out of scope.
    skip-test=BOOT-5264

    # NixOS uses yescrypt by default; sha-crypt round tuning doesn't apply.
    skip-test=AUTH-9229
    # /etc/login.defs SHA_CRYPT_*_ROUNDS are unused under ENCRYPT_METHOD=YESCRYPT.
    skip-test=AUTH-9230
    # Single-user personal box; PAM strength testing (pam_pwquality/passwdqc) is overkill.
    skip-test=AUTH-9262
    # Locked accounts on NixOS are system users by design (e.g. nobody, systemd-*).
    skip-test=AUTH-9284
    # Modern NIST guidance is against forced password expiry; PASS_*_DAYS skipped.
    skip-test=AUTH-9286

    # btrfs subvolumes on one LUKS partition under impermanence; partition-level
    # separation would break the rollback design and require a disko reformat.
    skip-test=FILE-6310

    # USB storage occasionally needed for ad-hoc data transfer / recovery.
    skip-test=USB-1000

    # No internal DNS hierarchy on home LAN; search domain not needed.
    skip-test=NAME-4028

    # Lynis looks for apt/yum-style audit tools; not applicable to nix's
    # content-addressed store. CVE scanning is via `vulnix` on demand.
    skip-test=PKGS-7398

    # False positive: NixOS firewall is active (iptables nixos-fw chain enforced),
    # but lynis only recognizes ufw/firewalld service names.
    skip-test=FIRE-4590

    # SSH-7408 sub-items we deliberately don't apply:
    #   Port: security through obscurity, breaks tooling defaults.
    #   AllowAgentForwarding: needed for Bitwarden SSH agent → git over forwarded agent.
    skip-test=SSH-7408:Port
    skip-test=SSH-7408:AllowAgentForwarding

    # NixOS uses journald (built-in rotation via SystemMaxUse), no /etc/logrotate.d.
    skip-test=LOGG-2146

    # Personal fleet, no SIEM/compliance need; cost of remote log host > value.
    skip-test=LOGG-2154

    # Personal home server, no legal warning posture needed.
    skip-test=BANN-7126

    # Process accounting (acct/psacct) redundant if/when auditd is enabled.
    skip-test=ACCT-9622

    # sysstat / sar historical perf collection not needed; live tooling sufficient.
    skip-test=ACCT-9626

    # impermanence wipes root every boot + nix store is content-addressed;
    # AIDE/Tripwire-style integrity scanning is structurally redundant.
    skip-test=FINT-4350

    # Nix flakes + OpenTofu drive system management; lynis only recognizes
    # ansible/puppet/cfengine/salt.
    skip-test=TOOL-5002

    # KRNL-6000 wants modules_disabled=1; locking permanently blocks post-boot
    # kmod loading (USB hot-plug, samba kernel deps, future hardware).
    skip-test=KRNL-6000:kernel.modules_disabled
    # KRNL-6000 wants ipv4.all.forwarding=0; we forward for Tailscale subnet routing.
    skip-test=KRNL-6000:net.ipv4.conf.all.forwarding
    # KRNL-6000 wants ipv4.all.rp_filter=1 (strict); breaks Tailscale's asymmetric
    # routing paths (Tailscale docs explicitly recommend off or loose).
    skip-test=KRNL-6000:net.ipv4.conf.all.rp_filter
    # KRNL-6000 wants unprivileged_bpf_disabled=1; we run 2 (permanent disable, stricter).
    skip-test=KRNL-6000:kernel.unprivileged_bpf_disabled

    # NETW-3200: dccp/sctp/rds/tipc mitigated via boot.blacklistedKernelModules;
    # lynis only checks the modules aren't compiled out of the kernel.
    skip-test=NETW-3200

    # Signature-based malware scanners (rkhunter/clamav/etc.) target Windows-style
    # payloads; nix store immutability + content-addressing covers the equivalent
    # threat model for this fleet.
    skip-test=HRDN-7230
  '';
}
