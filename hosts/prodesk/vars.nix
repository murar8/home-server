{
  vars = {
    hostname = "prodesk";
    user = "murar8";

    net = {
      ip = "192.168.1.130";
      prefixLength = 24;
      subnet = "192.168.1.0";
      subnetPrefix = "192.168.1.";
      gateway = "192.168.1.1";
      interface = "enp1s0";
      nameservers = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };

    tailnet = "tail87795f.ts.net";

    ssh = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCfqnufJrf3pZxXvFcqbB1vUhyc0EFuDBuUEO7Q0Luq lnzmrr@gmail.com";
    };
  };
}
