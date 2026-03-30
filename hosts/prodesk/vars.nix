let
  shared = import ../../vars.nix;
in
{
  vars = shared // {
    hostname = "prodesk";

    net = {
      ip = "192.168.1.130";
      prefixLength = 24;
      subnet = "192.168.1.0";
      subnetPrefix = "192.168.1.";
      gateway = "192.168.1.1";
      interface = "enp1s0";
      inherit (shared) nameservers;
    };

    tailnet = "tail87795f.ts.net";

    # https://wiki.nixos.org/wiki/Systemd_Hardening
    # shared baseline for all sandboxed services on this host
    serviceHardening = {
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };
}
