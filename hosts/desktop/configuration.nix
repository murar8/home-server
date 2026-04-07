{ pkgs, NixVirt, ... }:

let
  vmXML = vm: NixVirt.lib.domain.writeXML (import vm NixVirt.lib.xml);
in
{
  imports = [
    NixVirt.nixosModules.default
    ../../modules/base.nix
    ../../modules/desktop
    ../../modules/desktop/gnome
    ../../modules/boot/initrd-ssh.nix
    ../../modules/bridge-networking.nix
    ../../modules/virtualization/vfio-gpu.nix
    ../../modules/virtualization/looking-glass.nix
    ../../modules/virtualization/virt-manager
    ../../modules/virtualization/wol-vm-start
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
