{
  pkgs,
  inputs,
  flake,
  ...
}:

{
  imports = [
    inputs.NixVirt.nixosModules.default
    flake.modules.nixos.common
    flake.modules.nixos.desktop
    flake.modules.nixos.docker
    flake.modules.nixos.gnome
    flake.modules.nixos.keyd
    flake.modules.nixos.tailscale-client
    flake.modules.nixos.syncthing-client
    flake.modules.nixos.initrd-ssh
    flake.modules.nixos.static-ip
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
    connections."qemu:///system".domains =
      map
        (vm: {
          definition = flake.lib.mkWindowsVM vm;
          active = null;
        })
        [
          {
            name = "windows11";
            uuid = "10ef27aa-3f96-4ea1-a59b-eac6f6254132";
            memory = 16777216;
            macAddress = "52:54:00:43:9b:df";
            bootDisk = {
              dev = "vda";
              file = "/var/lib/libvirt/images/windows-11.img";
            };
            extraDisks = [
              {
                dev = "vdb";
                file = "/var/lib/libvirt/images/rocket-league.img";
              }
            ];
          }
          {
            name = "windows11-cracked";
            uuid = "8f37e9b3-b296-4762-b77e-e6d0b36b2da9";
            memory = 12582912;
            macAddress = "52:54:00:a2:81:16";
            bootDisk = {
              dev = "vda";
              file = "/var/lib/libvirt/images/windows-11-clone.img";
            };
            extraDisks = [
              {
                dev = "vdb";
                file = "/var/lib/libvirt/images/data.img";
              }
            ];
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
