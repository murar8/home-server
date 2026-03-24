# NixOS Machines

NixOS configurations for ThinkPad L15 Gen 2a
(AMD Ryzen 5 PRO 5650U, 512GB NVMe) and Debian desktop (planned).

## Commands

```sh
# Build locally
nixos-rebuild switch --flake .#thinkpad

# Format
nix fmt

# Lint
nix develop -c statix check .
nix develop -c nil diagnostics <file>

# Validate flake
nix flake check
```

## Disk/Boot

- LUKS + btrfs (subvols: @, @home, @nix, @log, @swap 8GB)
  on NVMe (`nvme-WDC_PC_SN730_SDBQNTY-512G-1001_21385B802308`)
- Secure Boot via lanzaboote v1.0.0 (keys in /var/lib/sbctl, managed with `sbctl`)
- No impermanence — persistent root
- WiFi (RTL8852AE) needs `rtw89` driver — `hardware.enableRedistributableFirmware = true` provides it

## Module Structure

- `configuration.nix` — core system: boot, users, dotfiles, services, packages
- `disk-config.nix` — disko partitioning (GPT, LUKS, btrfs subvolumes)
- `hardware-configuration.nix` — generated on installer with `nixos-generate-config`
- `flake.nix` — flake inputs, NixOS system config, formatter, dev shell, git-hooks
- `treefmt.nix` — treefmt formatter config (nixfmt, shellcheck, shfmt)

## Code Style

- Order attributes light-to-heavy: one-liners first, blocks last ("b shape")
- nixfmt `--strict` mode enabled — formatting is fully
  deterministic regardless of input
- nixfmt handles whitespace only — attribute ordering is a manual convention
- Modules that take no args use `_:` not `{ ... }:` (statix enforces this)

## Nix Gotchas

- New `.nix` files must be `git add`ed before
  `nix flake check` or rebuild — Nix sandbox only sees
  tracked files
- statix enforces merging repeated attrset keys
  (e.g., multiple `systemd.*` blocks must be combined)
- nil pre-commit hook has `denyWarnings = true` — unused
  bindings and other warnings fail the check
- Installer tmpfs may be too small for flake eval — use
  standalone `disko --mode destroy,format,mount` or
  `mount -o remount,size=4G /run`

## Verification

- Compare system derivations before/after refactoring:
  `nix eval --raw .#nixosConfigurations.thinkpad.config.system.build.toplevel`
- If output paths match, the NixOS config is byte-identical;
  if paths differ, use `nix store diff-closures <before> <after>`
  to check for actual package differences

## Reference: Home Server

- Home server config at `github:murar8/home-server`
  (or `../home-server/` locally)
- Server hostname: `prodesk` (192.168.1.130)
- Tailscale subnet routing captures LAN traffic to
  192.168.1.130 — disconnect TS for Samba access
