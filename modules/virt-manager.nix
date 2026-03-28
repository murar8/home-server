{ config, lib, ... }:

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
    virtualisation.libvirtd.enable = true;

    programs.virt-manager.enable = true;

    users.users.${cfg.user}.extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };
}
