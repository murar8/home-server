# ESP (p1) + LUKS (p2) managed by disko. Windows (p4) is unmanaged.
_: {
  disko.devices.disk.main = {
    device = "/dev/disk/by-id/nvme-CT1000P310SSD8_25185001BB57";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size = "953M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          priority = 2;
          size = "695366M";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/luks-pass";
            settings = {
              allowDiscards = true;
              crypttabExtraOpts = [ "tries=0" ];
            };
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "nixos"
                "-f"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
                  ];
                };
                "@vms" = {
                  mountpoint = "/var/lib/libvirt/images";
                  mountOptions = [ "noatime" ];
                };
                "@swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
