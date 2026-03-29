# NixOS Machines

NixOS configurations for personal machines:

- **Prodesk** — HP ProDesk 400 G3 SFF (i5-6500), home server with Home Assistant, Samba, Caddy, Syncthing, Tailscale, impermanence
- **ThinkPad L15 Gen 2a** — AMD Ryzen 5 PRO 5650U, 512GB NVMe
- **Debian desktop** — AMD Raphael/Granite Ridge, GTX 1070, 1TB NVMe

## Features

- Declarative disk layout via disko (LUKS + btrfs)
- Secure Boot via lanzaboote with TPM2 auto-unlock
- GNOME on Wayland with dconf-managed settings and extensions
- GPU passthrough (VFIO) and Looking Glass for Windows VMs
- Remote LUKS unlock via SSH in initrd
- Impermanence with btrfs rollback on boot (prodesk)
- Reverse proxy with Tailscale auto-TLS (prodesk)
