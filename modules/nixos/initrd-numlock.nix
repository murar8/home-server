{ pkgs, ... }:

{
  boot.initrd.systemd = {
    storePaths = [ "${pkgs.kbd}/bin/setleds" ];
    services.initrd-numlock = {
      description = "Enable NumLock in initrd";
      wantedBy = [ "cryptsetup.target" ];
      before = [ "cryptsetup.target" ];
      # cryptsetup.target runs before basic.target — must opt out of default
      # ordering deps to avoid a cycle via implicit After=basic.target.
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kbd}/bin/setleds -D +num";
        StandardInput = "tty";
        TTYPath = "/dev/tty0";
      };
    };
  };
}
