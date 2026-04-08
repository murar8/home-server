{
  pkgs,
  inputs,
  flake,
  ...
}:

let
  vmXML = vm: inputs.NixVirt.lib.domain.writeXML (import vm inputs.NixVirt.lib.xml);
in
{
  imports = [
    inputs.NixVirt.nixosModules.default
    flake.modules.nixos.common
    flake.modules.nixos.base
    flake.modules.nixos.desktop
    flake.modules.nixos.gnome
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.bridge-networking
    flake.modules.nixos.vfio-gpu
    flake.modules.nixos.looking-glass
    flake.modules.nixos.virt-manager
    flake.modules.nixos.wol-vm-start
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # TODO: revert to default when IOMMU group regression in 6.12.75+ is fixed (commit 7a126c1b6cfa)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "desktop";
  local.net.ip = "192.168.1.60";
  local.net.interface = "enp5s0";

  virtualisation.libvirt = {
    enable = true;
    swtpm.enable = true;
    connections."qemu:///system".domains = [
      {
        definition = vmXML ../../vms/windows11.nix;
        active = null;
      }
      {
        definition = vmXML ../../vms/windows11-cracked.nix;
        active = null;
      }
    ];
  };

  modules = {
    looking-glass.kvmfrSizeMB = 256;
    vfio-gpu.pciIds = [
      "10de:1b81" # GTX 1070 GPU
      "10de:10f0" # GTX 1070 Audio
      "1022:15b7" # USB controller (passthrough to VM)
    ];
  };
}
