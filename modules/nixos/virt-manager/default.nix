{
  config,
  lib,
  pkgs,
  ...
}:

let
  inhibitSuspendHook = pkgs.writeShellApplication {
    name = "vm-inhibit-suspend-hook";
    text = builtins.readFile ./vm-inhibit-suspend.sh;
  };
in

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
    hooks.qemu."inhibit-suspend" = lib.getExe inhibitSuspendHook;
  };

  programs.virt-manager.enable = true;

  systemd = {
    services.libvirtd.serviceConfig.LimitMEMLOCK = "infinity";
    tmpfiles.rules = [
      # nocow on VM images dir — new files inherit +C (btrfs CoW-on-CoW avoidance)
      "h /var/lib/libvirt/images - - - - +C"
      "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"
    ];
    services."vm-inhibit-suspend@" = {
      description = "Inhibit suspend while libvirt VM %i is running";
      serviceConfig = {
        Type = "simple";
        ExecStart = "systemd-inhibit --who=libvirt --why=\"VM %i is running\" ${pkgs.coreutils}/bin/sleep infinity";
      };
    };
  };

  users.users = {
    ${config.local.user}.extraGroups = [
      "libvirtd"
      "kvm"
    ];
    qemu-libvirtd.extraGroups = [ "kvm" ];
  };
}
