{
  config,
  lib,
  pkgs,
  ...
}:

let
  script = pkgs.writeShellApplication {
    name = "wol-vm-start";
    runtimeInputs = with pkgs; [
      socat
      xxd
      coreutils
      gawk
      gnugrep
      libvirt
    ];
    excludeShellChecks = [ "SC2162" ];
    text = builtins.readFile ./wol-vm-start.sh;
  };
in

{
  assertions = [
    {
      assertion = config.virtualisation.libvirtd.enable;
      message = "wol-vm-start requires libvirtd to be enabled.";
    }
  ];

  networking.firewall.allowedUDPPorts = [ 9 ];

  systemd.services.wol-vm-start = {
    description = "Wake-on-LAN listener for libvirt VMs";
    after = [
      "network.target"
      "libvirtd.service"
    ];
    wants = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.getExe script;
      Restart = "always";
      RestartSec = 5;
    };
  };
}
