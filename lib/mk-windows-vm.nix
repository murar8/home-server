# Shared base for VFIO GPU passthrough Windows 11 VMs.
# Takes inputs, then per-VM params, and returns a NixVirt domain XML derivation.
{ NixVirt, pkgs }:

{
  name,
  uuid,
  memory, # in KiB
  bootDisk, # { dev, file }
  extraDisks ? [ ], # [{ dev, file }]
  macAddress,
  kvmfrSizeMB ? 256,
}:

let
  vcpuCount = 14;

  pci = bus: slot: function: {
    type = "pci";
    domain = 0;
    inherit bus slot function;
  };

  pciHostdev = bus: slot: function: {
    mode = "subsystem";
    type = "pci";
    managed = true;
    source.address = {
      domain = 0;
      inherit bus slot function;
    };
  };

  mkDisk =
    { dev, file }:
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
    };

  # Pin vcpus to all cores except 0 and 8 (reserved for emulator)
  cpusets = builtins.filter (c: c != 0 && c != 8) (builtins.genList (i: i) 16);
in
NixVirt.lib.domain.writeXML {
  type = "kvm";
  inherit name uuid;

  metadata = with NixVirt.lib.xml; [
    (elem "libosinfo:libosinfo"
      [ (attr "xmlns:libosinfo" "http://libosinfo.org/xmlns/libvirt/domain/1.0") ]
      [ (elem "libosinfo:os" [ (attr "id" "http://microsoft.com/win/11") ] [ ]) ]
    )
  ];

  memory = {
    count = memory;
    unit = "KiB";
  };
  currentMemory = {
    count = memory;
    unit = "KiB";
  };
  memoryBacking = {
    locked = { };
  };

  vcpu = {
    placement = "static";
    count = vcpuCount;
  };

  cputune = {
    vcpupin = builtins.genList (i: {
      vcpu = i;
      cpuset = toString (builtins.elemAt cpusets i);
    }) vcpuCount;
    emulatorpin.cpuset = "0,8";
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "pc-q35-10.0";
    # Explicit OVMFFull loader + ms-keys vars template — required for EAC /
    # anti-cheat to see Secure Boot State: On inside Windows. SMM enforcement
    # comes from features.smm below; firmware autoselect can't be used because
    # no descriptor advertises this exact vars template path.
    loader = {
      path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
      readonly = true;
      type = "pflash";
    };
    nvram = {
      path = "/var/lib/libvirt/qemu/nvram/${name}_VARS.fd";
      template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
      templateFormat = "raw";
    };
    smbios = {
      mode = "host";
    };
  };

  features = {
    acpi = { };
    apic = { };
    pae = { };
    hyperv = {
      mode = "custom";
      relaxed = {
        state = true;
      };
      vapic = {
        state = true;
      };
      spinlocks = {
        state = true;
        retries = 8191;
      };
      vpindex = {
        state = true;
      };
      runtime = {
        state = true;
      };
      synic = {
        state = true;
      };
      stimer = {
        state = true;
        direct = {
          state = true;
        };
      };
      reset = {
        state = true;
      };
      vendor_id = {
        state = true;
        value = "AuthenticAMD";
      };
      frequencies = {
        state = true;
      };
      reenlightenment = {
        state = true;
      };
      tlbflush = {
        state = true;
      };
      ipi = {
        state = true;
      };
    };
    kvm = {
      hidden = {
        state = true;
      };
      hint-dedicated = {
        state = true;
      };
    };
    vmport = {
      state = false;
    };
    smm = {
      state = true;
    };
    ioapic = {
      driver = "kvm";
    };
  };

  cpu = {
    mode = "host-passthrough";
    check = "none";
    migratable = true;
    topology = {
      sockets = 1;
      dies = 1;
      cores = 7;
      threads = 2;
    };
    cache = {
      mode = "passthrough";
    };
    feature = [
      {
        policy = "require";
        name = "topoext";
      }
      {
        policy = "require";
        name = "svm";
      }
      # Hide the hypervisor CPUID flag from the guest. EAC and other anti-cheat
      # read this bit directly; without disabling it, KVM-hidden + Hyper-V
      # vendor spoofing isn't enough.
      {
        policy = "disable";
        name = "hypervisor";
      }
    ];
  };

  clock = {
    offset = "localtime";
    timer = [
      {
        name = "rtc";
        tickpolicy = "catchup";
      }
      {
        name = "pit";
        tickpolicy = "delay";
      }
      {
        name = "tsc";
        present = true;
        mode = "native";
      }
      {
        name = "hpet";
        present = false;
      }
      {
        name = "hypervclock";
        present = true;
      }
    ];
  };

  on_poweroff = "destroy";
  on_reboot = "restart";
  on_crash = "destroy";

  pm = {
    suspend-to-mem = {
      enabled = false;
    };
    suspend-to-disk = {
      enabled = false;
    };
  };

  devices = {
    emulator = "/run/current-system/sw/bin/qemu-system-x86_64";

    disk = [ (mkDisk bootDisk // { boot.order = 1; }) ] ++ map mkDisk extraDisks;

    controller = [
      {
        type = "usb";
        index = 0;
        model = "qemu-xhci";
        ports = 15;
        address = pci 2 0 0;
      }
      {
        type = "pci";
        index = 0;
        model = "pcie-root";
      }
      {
        type = "virtio-serial";
        index = 0;
        address = pci 3 0 0;
      }
      {
        type = "sata";
        index = 0;
        address = pci 0 31 2;
      }
    ];

    interface = {
      type = "bridge";
      mac = {
        address = macAddress;
      };
      source = {
        bridge = "br0";
      };
      model = {
        type = "virtio";
      };
      driver = {
        queues = 8;
      };
      address = pci 1 0 0;
    };

    serial = {
      type = "pty";
      target = {
        type = "isa-serial";
        port = 0;
        model = {
          name = "isa-serial";
        };
      };
    };

    console = {
      type = "pty";
      target = {
        type = "serial";
        port = 0;
      };
    };

    channel = {
      type = "spicevmc";
      target = {
        type = "virtio";
        name = "com.redhat.spice.0";
      };
      address = {
        type = "virtio-serial";
        controller = 0;
        bus = 0;
        port = 1;
      };
    };

    input = [
      {
        type = "mouse";
        bus = "ps2";
      }
      {
        type = "keyboard";
        bus = "ps2";
      }
    ];

    tpm = {
      model = "tpm-crb";
      backend = {
        type = "emulator";
        version = "2.0";
      };
    };

    graphics = {
      type = "spice";
      autoport = true;
      listen = {
        type = "address";
        address = "127.0.0.1";
      };
      image = {
        compression = false;
      };
      gl = {
        enable = false;
      };
    };

    audio = {
      id = 1;
      type = "spice";
    };

    video = {
      model = {
        type = "none";
      };
    };

    # GTX 1070 GPU + Audio + USB controller
    hostdev = [
      (pciHostdev 1 0 0)
      (pciHostdev 1 0 1)
      (pciHostdev 18 0 4)
    ];

    watchdog = {
      model = "itco";
      action = "shutdown";
    };

    memballoon = {
      model = "none";
    };

    panic = {
      model = "hyperv";
    };
  };

  qemu-commandline = {
    arg = [
      { value = "-device"; }
      { value = "{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"; }
      { value = "-object"; }
      {
        value = "{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':${
          toString (kvmfrSizeMB * 1024 * 1024)
        },'share':true}";
      }
    ];
  };
}
