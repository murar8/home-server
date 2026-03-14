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

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`.
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it.
- Intenso USB SSD needs `uas` kernel module in initrd (not just `usb_storage`).
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock.
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval.
- nix-copy-closure fails with "lacks a signature" — use `--build-host` to build on server instead.
