{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.wol-vm-start;

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
  options.modules.wol-vm-start.enable = lib.mkEnableOption "WoL listener to auto-start libvirt VMs";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.libvirtd.enable;
        message = "wol-vm-start requires libvirtd to be enabled.";
      }
    ];

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
  };
}
