# NixOS Machines

NixOS configurations for ThinkPad L15 Gen 2a
(AMD Ryzen 5 PRO 5650U, 512GB NVMe) and Debian desktop
(AMD Raphael/Granite Ridge, GTX 1070, Crucial P310 1TB).

## Claude Code Notes

- `pkexec` does not work for `nixos-rebuild` — use `--sudo` flag instead
  (pkexec changes cwd to /root and root can't access user's git repo)
- SSH keys are in Bitwarden agent (no files on disk) —
  use `ssh-add -L | grep lnzmrr` to extract public key;
  `ssh-copy-id` won't work, pipe to `authorized_keys` instead

## Commands

```sh
# Build locally (needs interactive terminal for sudo password — use `!` prefix in Claude Code)
nixos-rebuild switch --flake .#thinkpad --sudo

# Rebuild remotely from Debian desktop (needs interactive sudo)
nix run nixpkgs#nixos-rebuild -- switch --flake .#thinkpad \
  --target-host murar8@192.168.1.141 \
  --build-host murar8@192.168.1.141 \
  --sudo --ask-sudo-password

# Rebuild debian remotely from thinkpad (needs sudo password)
nixos-rebuild switch --flake .#debian \
  --target-host murar8@192.168.1.60 \
  --build-host murar8@192.168.1.60 \
  --ask-sudo-password

# Format
nix fmt

# Lint
nix develop -c statix check .
nix develop -c nil diagnostics <file>

# Validate flake
nix flake check
```

## Disk/Boot

- ThinkPad: LUKS + btrfs (subvols: @, @home, @nix, @log,
  @swap 8GB) on NVMe
  (`nvme-WDC_PC_SN730_SDBQNTY-512G-1001_21385B802308`)
- Debian: ESP (p1, 953M) + LUKS+btrfs (p2, 679G, subvols:
  @, @home, @nix, @log, @swap 16GB) + Windows NTFS (p4,
  251.5G) on NVMe (`nvme-CT1000P310SSD8_25185001BB57`)
- Debian initrd SSH unlock on port 2222 (static IP .60),
  uses r8169 NIC driver in initrd
- Secure Boot via lanzaboote v1.0.0
  (keys in /var/lib/sbctl, auto-generated + auto-enrolled)
- Secure Boot enrollment: set BIOS to Custom Mode, clear all
  keys to enter Setup Mode, boot NixOS — lanzaboote auto-enrolls
- FQ0001 firmware quirk (execute on SB violation) is common
  on consumer boards, not a blocker
- TPM2 auto-unlock (PCR 7) with password fallback;
  systemd initrd required
- No impermanence — persistent root
- WiFi (RTL8852AE) needs `rtw89` driver —
  `hardware.enableRedistributableFirmware = true` provides it

## TPM2 Auto-Unlock

- `boot.initrd.systemd.enable = true` required for
  `tpm2-device=auto` in crypttab
- TPM must be enrolled AFTER secure boot is fully enabled
  (PCR 7 reflects SB state)
- Enroll: `sudo systemd-cryptenroll --tpm2-device=auto
  --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks`
- Re-enroll after SB key changes: `--wipe-slot=tpm2`
  then re-enroll
- "TPM policy does not match" = PCR values changed since
  enrollment, re-enroll needed

## Install / Deploy

- nixos-anywhere supports non-root user with passwordless
  sudo (e.g., `nixos` user on installer) — no root SSH needed
- nixos-anywhere example:
  `nix run github:nix-community/nixos-anywhere --
  --flake .#debian --target-host nixos@<ip>`
- Default phases: kexec,disko,install,reboot — use
  `--phases install` to skip disko if already formatted
- `--disk-encryption-keys` copies from LOCAL machine to
  target (not target-local)
- `nix-copy-closure` fails with "lacks a signature" —
  use `--build-host` to build on target instead;
  remote rebuild must always use `--build-host`
- `nixos-rebuild` not on Debian — use
  `nix run nixpkgs#nixos-rebuild`

## Disko

- disko `--mode destroy,format,mount` runs `disk-deactivate`
  which `wipefs --all` on ALL partitions — use
  `--mode format,mount` to preserve existing data
- disko's `blkid TYPE` guard skips formatting partitions that
  already have a filesystem; `cryptsetup isLuks` guard skips
  existing LUKS — wipe header first if re-format is needed:
  `dd if=/dev/zero of=/dev/<part> bs=1M count=4`
- `sgdisk --new` fails on existing partitions; disko falls
  back to renaming only — delete partitions first if layout
  changes (sizes/count)
- disko partition sizes must be integers (`694412M` not
  `678.1G`) — use sector math to convert
- `wipefs` only erases magic bytes, not data — NTFS can be
  recovered by restoring the magic:
  `echo -ne 'NTFS    ' | dd of=/dev/<part> bs=1 seek=3 count=8`

## Module Structure

- `configuration.nix` — core system: boot, users,
  dotfiles, services, packages
- `disk-config.nix` — disko partitioning
  (GPT, LUKS, btrfs subvolumes)
- `hardware-configuration.nix` — generated on installer
  with `nixos-generate-config`
- `flake.nix` — flake inputs, NixOS system config,
  formatter, dev shell, git-hooks
- `treefmt.nix` — treefmt formatter config
  (nixfmt, shellcheck, shfmt)
- `modules/nvidia.nix` — reusable NVIDIA proprietary driver
  module (GTX 1070 uses stable/580.x)
- NetworkManager is per-host (thinkpad only) — debian uses
  systemd-networkd static IP from initrd config
- `dconf/user.ini` — GNOME dconf keyfile (settings,
  keybindings, extension configs); loaded via
  `programs.dconf.profiles.user.databases[].keyfiles`

## Code Style

- Order attributes light-to-heavy: one-liners first,
  blocks last ("b shape")
- nixfmt `--strict` mode enabled — formatting is fully
  deterministic regardless of input
- nixfmt handles whitespace only — attribute ordering
  is a manual convention
- Modules that take no args use `_:` not `{ ... }:`
  (statix enforces this)

## GNOME / dconf

- dconf keyfile format (INI) avoids translating GVariant
  types to Nix — use `dconf dump /` to export, edit file
- `lockAll = true` forces system defaults over user
  dconf db — required for settings to actually apply
- GNOME extensions must be both in `systemPackages` AND
  in `enabled-extensions` in the dconf keyfile
- Extensions need logout/login after rebuild to appear
- `@as []` is dconf syntax for empty string array
- Debian desktop settings reference:
  `~/.local/bin/reset-keybindings`

## Nix Gotchas

- New `.nix` files must be `git add`ed before
  `nix flake check` or rebuild — Nix sandbox only sees
  tracked files
- statix enforces merging repeated attrset keys
  (e.g., multiple `systemd.*` blocks must be combined)
- nil pre-commit hook has `denyWarnings = true` — unused
  bindings and other warnings fail the check
- `git-delta` is `delta` in nixpkgs — check names with
  `nix eval nixpkgs#<name>.name`
- Installer tmpfs may be too small for flake eval — use
  standalone `disko --mode destroy,format,mount` or
  `mount -o remount,size=4G /run`
- Downloaded binaries (Claude Code, etc.) need
  `programs.nix-ld.enable` + `services.envfs.enable`
  for FHS dynamic linking and /bin/* paths
- GNOME extensions may expect FHS paths like `/bin/ps`
  — envfs resolves these from system PATH
- `boot.initrd.systemd.network` config carries into booted
  system via systemd-networkd — NM sees interface as
  "connected externally" and won't manage it; set DNS via
  `networking.nameservers` if using static IP
- envfs + systemd initrd + fresh install = boot failure
  ("Refusing to run, /usr is not populated") — systemd v257
  made empty /usr fatal; fix: tmpfiles in initrd to pre-create
  /sysroot/usr/bin and /sysroot/bin (nixpkgs#494001, not yet
  in 25.11; workaround in common.nix)

## Verification

- Compare system derivations before/after refactoring:
  `nix eval --raw .#nixosConfigurations.thinkpad.config.system.build.toplevel`
- If output paths match, the NixOS config is byte-identical;
  if paths differ, use
  `nix store diff-closures <before> <after>`
  to check for actual package differences

## Reference: Home Server

- Home server config at `github:murar8/home-server`
  (or `../home-server/` locally)
- Debian desktop: `debian` (192.168.1.60)
- ThinkPad: `thinkpad` (192.168.1.141)
- Server hostname: `prodesk` (192.168.1.130)
- Tailscale subnet routing captures LAN traffic to
  192.168.1.130 — disconnect TS for Samba access
