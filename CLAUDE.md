# Home Server

HP ProDesk 400 G3 SFF (i5-6500, 4GB RAM, Realtek r8169 NIC) running NixOS 25.11 from internal SanDisk SSD PLUS 480GB (SATA).

## Commands

```sh
# Rebuild remotely (run in terminal — needs interactive sudo password prompt)
nix run nixpkgs#nixos-rebuild -- switch --flake .#server --target-host prodesk --build-host prodesk --ask-sudo-password

# Format
nix fmt

# Lint
nix develop -c statix check .
nix develop -c nil diagnostics <file>

# Validate flake
nix flake check
```

## Disk/Boot

- LUKS + btrfs (subvols: root, nix, persist, log, share, swap) on internal SATA SSD
- TPM2 modules (`tpm_tis`, `tpm_crb`) must be in `initrd.availableKernelModules` — internal SATA boots faster than USB, causing TPM race
- After LUKS header changes (resize, re-encrypt), TPM2 must be re-enrolled
- LUKS uses 4096-byte sectors; partition size must be multiple of 8 × 512-byte sectors or `cryptsetup resize` fails
- `disko --mode format,mount` is incremental for btrfs — skips existing filesystems/subvolumes, creates only new ones
- `disko --dry-run --mode <mode>` prints the generated script path — `cat` it to review
- Secure Boot via lanzaboote v1.0.0 (keys in /etc/secureboot)
- TPM2 auto-unlock (PCR 7); re-enroll if SB keys change: `printf "<password>" | sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --unlock-key-file=/dev/stdin /dev/disk/by-partlabel/disk-main-luks`
- SSH fallback unlock: `ssh prodesk-unlock`
- 4GB btrfs swapfile inside LUKS

## Impermanence

- Root btrfs subvol wiped on every boot via rollback.sh in initrd
- `root-blank` btrfs subvolume must be created manually after initial disko format (empty subvol used as snapshot source by rollback.sh)
- /tmp and /var/tmp are tmpfs (256M each) — required for systemd PrivateTmp sandboxing on btrfs
- Persistence entries live in each module alongside the service they support (NixOS merges them)
- Core system dirs (`/etc/secureboot`, `/var/lib/nixos`, `/var/lib/systemd/timers`) in `configuration.nix`
- Any new service storing state in /home or ephemeral paths needs explicit persistence entry

## Services

- Auto-upgrade via `system.autoUpgrade` in `configuration.nix` — daily ~04:00, pulls from `github:murar8/home-server#server` with `--recreate-lock-file --no-write-lock-file` (fresh nixpkgs, non-reproducible tradeoff accepted)
- Home Assistant in `home-assistant.nix`, port 8123, config managed declaratively; `.storage/` holds runtime state in /var/lib/hass
- Caddy reverse proxy with Tailscale auto-TLS; HA at `https://prodesk.tail87795f.ts.net`; cert cache in /var/lib/caddy (persisted)
- Syncthing GUI on 0.0.0.0:8384 (LAN-only firewall + Tailscale via trustedInterfaces); config in ~/.config/syncthing (persisted), data in ~/Documents
- Tailscale subnet router (192.168.1.0/24) + exit node; `useRoutingFeatures = "server"`; firewall trusts tailscale0
- ESPHome garden device (esp-garden) at 192.168.1.132 — config entry + noise PSK in .storage
- Samba share at `/share` (btrfs subvol), SMB3 encrypted, LAN-only (firewall + `hosts allow = 192.168.1.`); samba-wsdd for Windows discovery
- Samba user passwords managed via `smbpasswd -a <user>`; state in /var/lib/samba (persisted); `hosts allow` uses trailing-dot subnet syntax, not CIDR

## Module Structure

- Each module owns its service config, persistence entries, firewall ports, and systemd hardening
- Deleting a module should only require removing its import line
- `configuration.nix` — core system: boot, initrd, users, dotfiles, openssh, nix settings, core persistence
- `networking.nix` — networking, firewall base, Tailscale, Caddy (+ hardening), Syncthing, their persistence
- `samba.nix` — Samba, samba-wsdd, firewall ports, /share tmpfiles, samba persistence, smbd/nmbd hardening
- `hardening.nix` — kernel sysctls, module blacklist, audit, sudo, nix access control
- `home-assistant.nix` — Home Assistant config, lovelace dashboard, HA firewall port, hass persistence
- `vars.nix` — shared variables (hostname, user, network config, tailnet, SSH key)
- `lovelace.nix` — Home Assistant dashboard layout (imported by home-assistant.nix)
- `disk-config.nix` — disko partitioning (GPT, LUKS, btrfs subvolumes)
- `hardware-configuration.nix` — hardware-specific kernel modules and platform
- `flake.nix` — flake inputs, NixOS system config, formatter, dev shell, git-hooks
- `treefmt.nix` — treefmt formatter config (nixfmt, prettier, shellcheck, shfmt)

## SSH Hosts

- `prodesk` — main server (192.168.1.130)
- `prodesk-unlock` — initrd LUKS unlock (port 2222, physical NIC, not Tailscale)

## CI/CD

- GitHub Actions deploys Tailscale ACL policy via `tailscale/gitops-acl-action` on push to main
- ACL policy in `policy.hujson` (HuJSON = JSON + comments + trailing commas, NOT JSON5 — keys must be quoted)
- OAuth client needs `Policy File` read+write scope; secrets: `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET`, `TS_TAILNET`
- Tailnet Lock is enabled; new nodes need `tailscale lock sign <node-key>`

## Formatting

- Prettier handles YAML, JSON, Markdown, and HuJSON (via `.prettierrc.json` with `jsonc` parser)
- `treefmt.nix` `includes = [ "*.hujson" ]` adds HuJSON to prettier; config files must be git-tracked for Nix sandbox
- `.markdownlint.jsonc` extends `markdownlint/style/prettier` to avoid conflicts

## Code Style

- Order attributes light-to-heavy: one-liners first, blocks last ("b shape")
- nixfmt `--strict` mode enabled — formatting is fully deterministic regardless of input
- nixfmt handles whitespace only — attribute ordering is a manual convention

## Firewall

- `trustedInterfaces = ["tailscale0"]` accepts ALL traffic on Tailscale — port rules only affect the physical LAN
- Service ports (HA, Syncthing, Samba, wsdd) use interface-specific rules on `enp1s0`, not global `allowedTCPPorts`
- Samba/wsdd use manual firewall rules (not `openFirewall`) to restrict to LAN interface

## Tailscale Gotchas

- `permitCertUid = "caddy"` required for Caddy to fetch Tailscale TLS certs
- Caddy can't share ports with backend services — use default 443, not service ports
- Subnet routes need ACL grant: `{"src": ["autogroup:member"], "dst": ["192.168.1.0/24"], "ip": ["*"]}`
- `extraUpFlags` only runs on first login; use `extraSetFlags` for persistent settings
- `useRoutingFeatures = "server"` required for subnet router/exit node (enables IP forwarding)

## Nix Gotchas

- New `.nix` files must be `git add`ed before `nix flake check` or rebuild — Nix sandbox only sees tracked files
- `boot.initrd.network.ssh` is the correct initrd SSH option even with `boot.initrd.systemd.enable = true` — the module handles both paths internally
- `nixos-rebuild-ng` (NixOS 25.11) wraps all remote `--sudo` commands through `sudo /bin/sh -c` — command-specific NOPASSWD sudoers rules don't work; use `--ask-sudo-password` instead
- `--ask-sudo-password` requires interactive terminal — Claude Code cannot run rebuilds
- statix enforces merging repeated attrset keys (e.g., multiple `systemd.*` blocks must be combined)
- nil pre-commit hook has `denyWarnings = true` — unused bindings and other warnings fail the check
- Modules that take no args use `_:` not `{ ... }:` (statix enforces this)
- Server has no `rsync`/`parted`/`sgdisk` — use `nix-shell -p <pkg>` or `nix run` for one-off tools

## Verification

- Compare system derivations before/after refactoring: `nix eval --raw .#nixosConfigurations.server.config.system.build.toplevel`
- If output paths match, the NixOS config is byte-identical; if paths differ, use `nix store diff-closures <before> <after>` to check for actual package differences

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`.
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it.
- Intenso USB SSD needs `uas` kernel module in initrd (not just `usb_storage`).
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock.
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval.
- nix-copy-closure fails with "lacks a signature" — use `--build-host` to build on server instead.
