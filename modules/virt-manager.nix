{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.virt-manager;
in

{
  options.modules.virt-manager.user = lib.mkOption {
    type = lib.types.str;
    default = "murar8";
    description = "User to add to libvirtd and kvm groups.";
  };

  config = {
    virtualisation.libvirtd = {
      enable = true;
      qemu.runAsRoot = false;
    };

    programs.virt-manager.enable = true;

    systemd.services.libvirtd.serviceConfig.LimitMEMLOCK = "infinity";

    systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];

    users.users = {
      ${cfg.user}.extraGroups = [
        "libvirtd"
        "kvm"
      ];
      qemu-libvirtd.extraGroups = [ "kvm" ];
    };
  };
}
