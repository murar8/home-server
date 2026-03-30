# NixOS Machines

Multi-host NixOS flake: Prodesk (home server), ThinkPad (laptop), Debian (desktop).

## Hosts

- **Prodesk** (`prodesk`, 192.168.1.130) — HP ProDesk 400 G3 SFF, NixOS 25.11, impermanence
- **ThinkPad** (`thinkpad`, 192.168.1.141) — ThinkPad L15 Gen 2a, GNOME
- **Debian** (`debian`, 192.168.1.60) — AMD desktop, VFIO GPU passthrough
- `prodesk-unlock` — initrd LUKS unlock (port 2222)

## Commands

```sh
# Prodesk (remote — needs interactive terminal)
nix run nixpkgs#nixos-rebuild -- switch --flake .#prodesk \
  --target-host prodesk --build-host prodesk --ask-sudo-password

# ThinkPad (local — needs interactive terminal)
nixos-rebuild switch --flake .#thinkpad --sudo

# ThinkPad (remote)
nix run nixpkgs#nixos-rebuild -- switch --flake .#thinkpad \
  --target-host murar8@192.168.1.141 \
  --build-host murar8@192.168.1.141 \
  --sudo --ask-sudo-password

# Debian (remote)
nixos-rebuild switch --flake .#debian \
  --target-host murar8@192.168.1.60 \
  --build-host murar8@192.168.1.60 \
  --ask-sudo-password

nix fmt                              # format
nix develop -c statix check .        # lint
nix develop -c nil diagnostics <file>
nix flake check                      # validate
```

## Code Style

- Order attributes light-to-heavy: one-liners first, blocks last ("b shape")
- Modules that take no args use `_:` not `{ ... }:` (statix enforces this)
- Shell scripts live alongside their `.nix` module, loaded via `writeShellApplication` + `builtins.readFile`

## Prodesk Gotchas

- **Impermanence**: root btrfs subvol wiped every boot; any new service storing state needs an explicit persistence entry in its module
- **Persistence ownership**: each module owns its config, persistence, firewall, and hardening
- LUKS uses 4096-byte sectors; partition size must be multiple of 8 x 512-byte sectors or `cryptsetup resize` fails
- TPM2 modules (`tpm_tis`, `tpm_crb`) must be in `initrd.availableKernelModules` — SATA boots faster than USB, causing TPM race
- TPM2 re-enroll after SB key changes: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks`
- `root-blank` subvol must be created manually after initial disko format
- /tmp and /var/tmp are tmpfs (256M each) — required for systemd PrivateTmp on btrfs
- Samba `hosts allow` uses trailing-dot subnet syntax (`192.168.1.`), not CIDR
- Samba user passwords managed via `smbpasswd -a <user>`

## GNOME / dconf Gotchas

- `lockAll = true` forces system defaults over user dconf db
- dconf-reset service clears user db on login — logout/login after rebuild
- Extensions must be in both `systemPackages` and `enabled-extensions`
- dash-to-dock: 3 hotkey families x 10 — all must be disabled to free Super+N
- Keybinding conventions: Super=focus, +Shift=move, +Ctrl=geometry, +Alt=workspace; hjkl = arrows

## Tailscale Gotchas

- `permitCertUid = "caddy"` required for Caddy to fetch TLS certs
- Subnet routes need ACL grant in `policy.hujson`
- `extraUpFlags` only runs on first login; use `extraSetFlags` for persistent settings
- Tailscale subnet routing captures LAN traffic to .130 — disconnect TS for Samba access

## Nix Gotchas

- New `.nix` files must be `git add`ed before build/check
- `--ask-sudo-password` requires interactive terminal — Claude Code cannot run rebuilds
- `boot.initrd.network.ssh` is the correct initrd SSH option even with `boot.initrd.systemd.enable = true`
- statix enforces merging repeated attrset keys
- nil pre-commit hook has `denyWarnings = true`
- `writeShellApplication` adds shebang + `set -euo pipefail` — don't duplicate
- systemd service PATH only has systemd bin — use absolute nix store paths in `ExecStart`
- `boot.initrd.systemd.network` carries into booted system via systemd-networkd
- envfs + systemd initrd + fresh install = boot failure (systemd v257); workaround in common.nix
- `pkexec` does not work for `nixos-rebuild` — use `--sudo` flag instead
- Remote rebuild must always use `--build-host` (nix-copy-closure fails with "lacks a signature")
- SSH keys are in Bitwarden agent (no files on disk) — use `ssh-add -L | grep lnzmrr` to extract public key
- Prodesk has no `rsync`/`parted`/`sgdisk` — use `nix-shell -p <pkg>` or `nix run`

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval
