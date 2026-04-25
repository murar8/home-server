{ pkgs, ... }:

{
  boot.initrd.systemd = {
    storePaths = [ "${pkgs.kbd}/bin/setleds" ];
    services.initrd-numlock = {
      description = "Enable NumLock in initrd";
      wantedBy = [ "initrd.target" ];
      before = [ "cryptsetup.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kbd}/bin/setleds -D +num";
        StandardInput = "tty";
        TTYPath = "/dev/tty0";
      };
    };
  };
}
