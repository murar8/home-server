# Generated from nixos-generate-config on desktop
# CPU: AMD Raphael/Granite Ridge (kvm-amd) | GPU: NVIDIA GTX 1070 + AMD Radeon iGPU
# NVMe: Crucial P310 1TB | NIC: Realtek RTL8126 5GbE
{ config, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "hid_generic"
    "usb_storage"
    "sd_mod"
    "r8169"
  ];
  boot.kernelModules = [ "kvm-amd" ];
}
