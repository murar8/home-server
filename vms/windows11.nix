xml:

let
  inherit (import ./lib.nix) rawDisk;
in
import ./base.nix {
  inherit xml;

  name = "windows11";
  uuid = "10ef27aa-3f96-4ea1-a59b-eac6f6254132";
  memory = 16777216;
  macAddress = "52:54:00:43:9b:df";
  nvramPath = "/var/lib/libvirt/qemu/nvram/windows11_VARS.fd";

  disks = [
    (rawDisk "/var/lib/libvirt/images/windows-11.img" "vda" { boot.order = 1; })
    (rawDisk "/var/lib/libvirt/images/rocket-league.img" "vdb" { })
  ];
}
