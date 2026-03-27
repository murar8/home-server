# Generated from nixos-generate-config on ThinkPad L15 Gen 2a
# CPU: AMD Ryzen 5 PRO 5650U (6c/12t) | GPU: AMD Radeon Vega (amdgpu)
# NVMe: WDC PC SN730 512GB | WiFi: Realtek RTL8852AE (rtw89)
{ config, lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "xhci_pci_renesas"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
    "tpm_tis"
    "tpm_crb"
  ];
  boot.kernelModules = [ "kvm-amd" ];
}
