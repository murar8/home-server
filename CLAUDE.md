# NixOS Machines

## Hosts

- **Prodesk** (`prodesk`, 192.168.1.130) — HP ProDesk 400 G3 SFF, home server, NixOS 25.11, impermanence, Home Assistant, Samba, Caddy, Syncthing, Tailscale
- **ThinkPad** (`thinkpad`, 192.168.1.141) — ThinkPad L15 Gen 2a, NetworkManager, GNOME
- **Debian** (`debian`, 192.168.1.60) — AMD desktop, systemd-networkd, VFIO GPU passthrough, Looking Glass
- `prodesk-unlock` — initrd LUKS unlock (port 2222, physical NIC)

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

## Repo Layout

- `hosts/<name>/` — per-host config, disk layout, hardware
- `modules/` — shared NixOS modules (common.nix, gnome.nix, initrd-ssh.nix, etc.)
- `vms/` — libvirt VM definitions (debian only)
- `flake.nix` — inputs, nixosConfigurations (prodesk, thinkpad, debian), formatter, dev shell
- `treefmt.nix` — formatter config (nixfmt, prettier, shellcheck, shfmt)
- `policy.hujson` — Tailscale ACL policy (deployed via GitHub Actions)

## Code Style

- Order attributes light-to-heavy: one-liners first, blocks last ("b shape")
- nixfmt `--strict` — formatting is fully deterministic
- Modules that take no args use `_:` not `{ ... }:` (statix enforces this)
- Shell scripts live alongside their `.nix` module, loaded via `writeShellApplication` + `builtins.readFile`

## Prodesk: Disk/Boot

- LUKS + btrfs (subvols: root, nix, persist, log, share, swap) on internal SATA SSD
- LUKS uses 4096-byte sectors; partition size must be multiple of 8 x 512-byte sectors or `cryptsetup resize` fails
- TPM2 modules (`tpm_tis`, `tpm_crb`) must be in `initrd.availableKernelModules` — SATA boots faster than USB, causing TPM race
- Secure Boot via lanzaboote v1.0.0; TPM2 auto-unlock (PCR 7)
- TPM2 re-enroll after SB key changes: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks`
- SSH fallback unlock: `ssh prodesk-unlock`
- `disko --mode format,mount` is incremental for btrfs — skips existing filesystems/subvolumes
- `disko --dry-run --mode <mode>` prints the generated script path — `cat` it to review

## Prodesk: Impermanence

- Root btrfs subvol wiped on every boot via rollback.sh in initrd
- `root-blank` subvol must be created manually after initial disko format
- /tmp and /var/tmp are tmpfs (256M each) — required for systemd PrivateTmp on btrfs
- Persistence entries live in each module alongside the service they support
- Any new service storing state in /home or ephemeral paths needs explicit persistence entry

## Prodesk: Services

- Auto-upgrade daily ~04:00 from `github:murar8/home-server#prodesk` with `--recreate-lock-file`
- Home Assistant on port 8123; Caddy reverse proxy with Tailscale auto-TLS at `https://prodesk.tail87795f.ts.net`
- Syncthing GUI on 0.0.0.0:8384 (LAN-only firewall + Tailscale via trustedInterfaces)
- Tailscale subnet router (192.168.1.0/24) + exit node; `useRoutingFeatures = "server"`
- Samba share at `/share`, SMB3 encrypted, LAN-only; samba-wsdd for discovery
- Samba `hosts allow` uses trailing-dot subnet syntax (`192.168.1.`), not CIDR
- Samba user passwords managed via `smbpasswd -a <user>`

## Prodesk: Module Structure

- Each module owns its config, persistence, firewall ports, and hardening
- `hosts/prodesk/configuration.nix` — core system, boot, users, dotfiles, openssh, persistence
- `hosts/prodesk/networking.nix` — firewall, Tailscale, Caddy, Syncthing
- `hosts/prodesk/samba.nix` — Samba, samba-wsdd, /share
- `hosts/prodesk/hardening.nix` — kernel sysctls, module blacklist, audit, sudo
- `hosts/prodesk/home-assistant.nix` / `lovelace.nix` — Home Assistant + dashboard
- `hosts/prodesk/vars.nix` — shared variables (hostname, user, network config, tailnet, SSH key)

## Prodesk: Firewall

- `trustedInterfaces = ["tailscale0"]` — port rules only affect physical LAN
- Service ports use interface-specific rules on `enp1s0`, not global `allowedTCPPorts`
- Samba/wsdd use manual firewall rules (not `openFirewall`) to restrict to LAN

## GNOME / dconf

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

## Formatting

- Prettier handles YAML, JSON, Markdown, and HuJSON (via `.prettierrc.json` with `jsonc` parser)
- `treefmt.nix` `includes = [ "*.hujson" ]` adds HuJSON to prettier; config files must be git-tracked for Nix sandbox
- `.markdownlint.jsonc` extends `markdownlint/style/prettier` to avoid conflicts

## Nix Gotchas

- New `.nix` files must be `git add`ed before build/check
- `boot.initrd.network.ssh` is the correct initrd SSH option even with `boot.initrd.systemd.enable = true` — the module handles both paths
- `--ask-sudo-password` requires interactive terminal — Claude Code cannot run rebuilds
- statix enforces merging repeated attrset keys
- nil pre-commit hook has `denyWarnings = true`
- `writeShellApplication` adds shebang + `set -euo pipefail` — don't duplicate
- systemd service PATH only has systemd bin — use absolute nix store paths in `ExecStart`
- `boot.initrd.systemd.network` carries into booted system via systemd-networkd
- envfs + systemd initrd + fresh install = boot failure (systemd v257); workaround in common.nix
- Downloaded binaries need `nix-ld` + `envfs`
- `pkexec` does not work for `nixos-rebuild` — use `--sudo` flag instead
- Remote rebuild must always use `--build-host` (nix-copy-closure fails with "lacks a signature")
- SSH keys are in Bitwarden agent (no files on disk) — use `ssh-add -L | grep lnzmrr` to extract public key
- Prodesk has no `rsync`/`parted`/`sgdisk` — use `nix-shell -p <pkg>` or `nix run`

## Verification

- Compare derivations: `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel`
- If paths match, config is byte-identical; if different, `nix store diff-closures <before> <after>`

## CI/CD

- GitHub Actions deploys Tailscale ACL from `policy.hujson` (HuJSON — keys must be quoted)
- Tailnet Lock enabled; new nodes need `tailscale lock sign <node-key>`

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval
- nix-copy-closure fails with "lacks a signature" — use `--build-host` to build on server instead
