# NixOS Machines

NixOS configurations for personal machines.
Will contain configs for both ThinkPad and Debian desktop.

## Current State

### ThinkPad L15 Gen 2a (migration in progress)

**Backup complete** on `prodesk:/share/thinkpad-backup/`:

| Category | Contents | Status |
| -------- | -------- | ------ |
| Browser profiles | Firefox (4.4GB), Chrome (1.2GB), Chromium (21MB) | Done |
| Credentials | SSH, GPG, gh, Bitwarden, AWS, kube, Docker, etc. | Done |
| GNOME settings | dconf dump | Done |
| User data | Projects (1.5GB), Pictures, Videos | Done |
| User data (synced) | Documents, Downloads | Skipped (Syncthing) |
| Dotfiles | .dotfiles bare repo | Skipped (re-clone from github:murar8/dotfiles) |
| App state | Thunderbird, alacritty config | Done |
| Flatpak data | Slack (1.8GB), Bottles (1.8GB), Thunderbird, etc. | Done |
| System reference | /etc snapshot, hardware info | Done |
| WiFi passwords | /etc/NetworkManager/system-connections/ | TODO (needs manual `sudo rsync`) |

**Device ready to wipe.**

### Hardware Summary

- **CPU**: AMD Ryzen 5 PRO 5650U (Cezanne)
- **GPU**: AMD Radeon Vega (integrated, amdgpu)
- **NVMe**: WDC PC SN730 512GB
  (`nvme-WDC_PC_SN730_SDBQNTY-512G-1001_21385B802308`)
- **WiFi**: Realtek RTL8852AE (rtw89 driver)
- **Ethernet**: Realtek RTL8111 (r8169 driver)
- **Bluetooth**: yes
- **Product**: 20X7003SIX / ThinkPad L15 Gen 2a

### Debian Desktop (192.168.1.60, planned)

- **OS**: Debian 13 trixie, MSI MS-7E28
- **Disk**: 932GB NVMe, 96% full + 251GB unpartitioned
- **Gaming**: Moonlight, MangoHud, gamescope, Bottles/Wine, Looking Glass, libvirt
- **Browsers**: Firefox (same profile), Chrome, Brave, Chromium, Edge
- **Will need**: GPU passthrough/gaming setup, libvirt/KVM

## Decisions Made

- **Username**: `murar8` (unify with server and debian)
- **NixOS style**: Disko + persistent root (no impermanence)
- **Desktop**: GNOME on Wayland
- **Packages**: Nix preferred (no flatpak/snap unless necessary)
- **Channel**: NixOS 25.11 stable
- **Home-manager**: Not now
- **Config repo**: This repo (separate from home-server), shared for both machines
- **SSH keys**: Stored in Bitwarden, no backup needed

## TODO for next session

1. **WiFi backup** — run manually before wiping:

   ```bash
   sudo rsync -ah \
     /etc/NetworkManager/system-connections/ \
     prodesk:/share/thinkpad-backup/wifi-connections/
   ```

2. **Create NixOS config** (from the new machine or prodesk):
   - `flake.nix` — inputs: nixpkgs 25.11, disko, dotfiles, treefmt-nix, git-hooks
   - `disk-config.nix` — LUKS + btrfs
     (subvols: @, @home, @nix, @log, @swap 8GB)
   - `configuration.nix` — GNOME/GDM/Wayland, NetworkManager,
     systemd-boot, user murar8, all packages
   - `hardware-configuration.nix` — generate on installer with `nixos-generate-config`
   - Reference: home-server config at `github:murar8/home-server`

3. **Install NixOS** from USB ISO:
   - Boot installer, connect WiFi, clone this repo
   - Run disko, generate hw config, `nixos-install --flake .#thinkpad`

4. **Restore from backup** (`prodesk:/share/thinkpad-backup/`):
   - Credentials first (SSH, GPG, gh, etc.)
   - Browser profiles BEFORE first browser launch (critical for sessions)
   - Remove Chrome/Chromium SingletonLock files after restore
   - `sudo chown -R murar8:users /home/murar8/` (fix ownership from lmurarotto→murar8)
   - Selective dconf load (review for Ubuntu-specific keys first)
   - Clone dotfiles:
     `git clone --bare git@github.com:murar8/dotfiles.git ~/.dotfiles`

5. **Verify**: browser sessions, SSH/GPG, cloud CLIs, dev tools, Syncthing, Tailscale, WiFi

## Gotchas

- Tailscale subnet routing captures LAN traffic to
  192.168.1.130 — disconnect TS for Samba access
- Ubuntu CIFS client needs `vers=3.1.1,seal` for the
  server's SMB3+encryption config
- Firefox profile is `hfhs6f31.default` — same name on
  both ThinkPad and Debian (syncthing)
- ThinkPad WiFi (RTL8852AE) needs `rtw89` driver —
  ensure `hardware.enableRedistributableFirmware = true`
- Installer tmpfs may be too small for flake eval —
  use standalone disko, or `mount -o remount,size=4G /run`
