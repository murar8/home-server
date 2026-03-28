_:

{
  imports = [
    ../../modules/common.nix
    ../../modules/gaming.nix
    ../../modules/initrd-ssh.nix
    ../../modules/looking-glass.nix
    ../../modules/vfio-gpu.nix
    ../../modules/virt-manager.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking = {
    hostName = "debian";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };

  modules = {
    vfio-gpu.pciIds = [
      "10de:1b81" # GTX 1070 GPU
      "10de:10f0" # GTX 1070 Audio
    ];
    initrd-ssh = {
      interface = "enp5s0";
      address = [ "192.168.1.60/24" ];
      gateway = [ "192.168.1.1" ];
    };
  };
}
