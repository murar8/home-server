{ pkgs, NixVirt, ... }:

let
  vmXML = vm: NixVirt.lib.domain.writeXML (import vm NixVirt.lib.xml);
in
{
  imports = [
    NixVirt.nixosModules.default
    ../../modules/desktop.nix
    ../../modules/gnome.nix
    ../../modules/initrd-ssh.nix
    ../../modules/looking-glass.nix
    ../../modules/vfio-gpu.nix
    ../../modules/virt-manager.nix
    ../../modules/wol-vm-start.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # TODO: revert to default when IOMMU group regression in 6.12.75+ is fixed (commit 7a126c1b6cfa)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "desktop";
    useNetworkd = true;
    networkmanager.enable = false;
    firewall.allowedUDPPorts = [ 9 ]; # WoL magic packets for VM auto-start
  };

  systemd.network = {
    links."20-enp5s0" = {
      matchConfig.OriginalName = "enp5s0";
      linkConfig.WakeOnLan = "magic";
    };
    netdevs."20-br0".netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
    networks = {
      "20-enp5s0" = {
        matchConfig.Name = "enp5s0";
        networkConfig.Bridge = "br0";
      };
      "20-br0" = {
        matchConfig.Name = "br0";
        address = [ "192.168.1.60/24" ];
        gateway = [ "192.168.1.1" ];
      };
    };
  };

  # nocow on VM images dir — new files inherit +C (btrfs CoW-on-CoW avoidance)
  systemd.tmpfiles.rules = [ "h /var/lib/libvirt/images - - - - +C" ];

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
    wol-vm-start.enable = true;
    initrd-ssh = {
      interface = "enp5s0";
      address = [ "192.168.1.60/24" ];
      gateway = [ "192.168.1.1" ];
    };
  };
}
