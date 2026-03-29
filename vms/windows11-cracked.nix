xml:

let
  inherit (import ./lib.nix) rawDisk;
in
import ./base.nix {
  inherit xml;

  name = "windows11-cracked";
  uuid = "8f37e9b3-b296-4762-b77e-e6d0b36b2da9";
  memory = 12582912;
  macAddress = "52:54:00:a2:81:16";
  nvramPath = "/var/lib/libvirt/qemu/nvram/windows11-cracked_VARS.fd";

  disks = [
    (rawDisk "/var/lib/libvirt/images/windows-11-clone.img" "vda" { boot.order = 1; })
    (rawDisk "/var/lib/libvirt/images/data.img" "vdb" { })
  ];
}
