# NixOS Machines

NixOS configurations for personal machines:

- **ThinkPad L15 Gen 2a** — AMD Ryzen 5 PRO 5650U, 512GB NVMe
- **Debian desktop** — AMD Raphael/Granite Ridge, GTX 1070, 1TB NVMe

## Features

- Declarative disk layout via disko (LUKS + btrfs)
- Secure Boot via lanzaboote with TPM2 auto-unlock
- GNOME on Wayland with dconf-managed settings and extensions
- GPU passthrough (VFIO) and Looking Glass for Windows VMs
- Remote LUKS unlock via SSH in initrd
- Suspend inhibitor while libvirt VMs are running
- Wake-on-LAN listener for auto-starting VMs
