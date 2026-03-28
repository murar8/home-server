{ config, lib, ... }:

{
  options.modules.vfio-gpu.pciIds = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "PCI vendor:device IDs to bind to vfio-pci.";
    example = [
      "10de:1b81"
      "10de:10f0"
    ];
  };

  config = {
    assertions = [
      {
        assertion =
          config.hardware.cpu.amd.updateMicrocode || builtins.elem "kvm-amd" config.boot.kernelModules;
        message = "vfio-gpu module uses amd_iommu=on and requires an AMD CPU.";
      }
    ];

    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];
      # AMD-only; use intel_iommu=on for Intel hosts
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=${lib.concatStringsSep "," config.modules.vfio-gpu.pciIds}"
      ];
    };
  };
}
