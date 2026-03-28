{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.looking-glass.kvmfrSizeMB = lib.mkOption {
    type = lib.types.ints.positive;
    default = 64;
    description = "KVMFR static shared memory size in MB.";
  };

  config = {
    assertions = [
      {
        assertion = config.virtualisation.libvirtd.enable;
        message = "Looking Glass requires libvirtd to be enabled.";
      }
    ];

    boot = {
      extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
      kernelModules = [ "kvmfr" ];
      kernelParams = [ "kvmfr.static_size_mb=${toString config.modules.looking-glass.kvmfrSizeMB}" ];
    };

    services.udev.packages = lib.singleton (
      pkgs.writeTextFile {
        name = "kvmfr-udev-rules";
        text = ''
          SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
        '';
        destination = "/etc/udev/rules.d/70-kvmfr.rules";
      }
    );

    virtualisation.libvirtd.qemu.verbatimConfig = ''
      namespaces = []
      cgroup_device_acl = [
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm",
        "/dev/rtc", "/dev/hpet",
        "/dev/vfio/vfio", "/dev/kvmfr0"
      ]
    '';

    environment.systemPackages = [ pkgs.looking-glass-client ];
  };
}
