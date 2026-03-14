# Home Server

HP ProDesk 400 G3 SFF (i5-6500, 4GB RAM, Realtek r8169 NIC) running NixOS 25.11 from USB SSD (Intenso Portable SSD).

## Commands

```sh
# Rebuild remotely
nix run nixpkgs#nixos-rebuild -- switch --flake .#server --target-host prodesk --build-host prodesk --sudo

# Format
nix fmt

# Lint
nix develop -c statix check .
nix develop -c nil diagnostics <file>

# Validate flake
nix flake check
```

## Disk/Boot

- LUKS + btrfs (subvols: root, nix, persist, log, swap) on USB SSD
- Secure Boot via lanzaboote v1.0.0 (keys in /etc/secureboot)
- TPM2 auto-unlock (PCR 7); re-enroll if SB keys change: `printf "<password>" | sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --unlock-key-file=/dev/stdin /dev/disk/by-partlabel/disk-main-luks`
- SSH fallback unlock: `ssh prodesk-unlock`
- 4GB btrfs swapfile inside LUKS

## Impermanence

- Root btrfs subvol wiped on every boot via rollback.sh in initrd
- /tmp and /var/tmp are tmpfs (256M each) — required for systemd PrivateTmp sandboxing on btrfs
- Persistent dirs listed in `environment.persistence."/persist".directories`
- HA utility meters and Tailscale state persist via /persist system directories
- Syncthing config persists via user home dirs (`environment.persistence."/persist".users`)
- Any new service storing state in /home or ephemeral paths needs explicit persistence entry

## Services

- Home Assistant on port 8123, config managed declaratively; `.storage/` holds runtime state in /var/lib/hass
- Syncthing GUI on 0.0.0.0:8384 (Tailscale-only via firewall); config in ~/.config/syncthing (persisted), data in ~/Documents
- Tailscale subnet router (192.168.1.0/24) + exit node; `useRoutingFeatures = "server"`; firewall trusts tailscale0
- ESPHome garden device (esp-garden) at 192.168.1.132 — config entry + noise PSK in .storage

## SSH Hosts

- `prodesk` — main server (192.168.1.130)
- `prodesk-unlock` — initrd LUKS unlock (port 2222)

## Tailscale Gotchas

- Subnet routes need ACL grant: `{"src": ["autogroup:member"], "dst": ["192.168.1.0/24"], "ip": ["*"]}`
- `extraUpFlags` only runs on first login; use `extraSetFlags` for persistent settings
- `useRoutingFeatures = "server"` required for subnet router/exit node (enables IP forwarding)

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`.
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it.
- Intenso USB SSD needs `uas` kernel module in initrd (not just `usb_storage`).
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock.
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval.
- nix-copy-closure fails with "lacks a signature" — use `--build-host` to build on server instead.
