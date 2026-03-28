{
  rawDisk =
    file: dev: extra:
    {
      type = "file";
      device = "disk";
      driver = {
        name = "qemu";
        type = "raw";
        cache = "none";
        io = "native";
        discard = "unmap";
      };
      source = { inherit file; };
      target = {
        inherit dev;
        bus = "virtio";
      };
    }
    // extra;
}
