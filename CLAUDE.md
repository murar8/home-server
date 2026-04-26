# NixOS Machines

See [README.md](./README.md) for host overview and deploy commands. Extra details Claude needs:

- Prodesk runs impermanence; `prodesk-unlock` is initrd LUKS on port 2222
- IPs: prodesk `192.168.1.130`, thinkpad `192.168.1.141`, desktop `192.168.1.60`

## Dev commands

```sh
nix fmt                              # format
nix flake check                      # validate (new .nix files must be `git add`ed first)
```

## Module Hierarchy

Flake uses [numtide/blueprint](https://github.com/numtide/blueprint) for convention-based output generation. Modules live in `modules/nixos/` and are auto-discovered as `flake.modules.nixos.<name>`. Host entry points live in `hosts/<name>/configuration.nix`, which wire up modules via `flake.modules.nixos.*` and `inputs.*` (no relative paths).

Host opt-ins (beyond `common`, snapshot — authoritative source is `hosts/*/configuration.nix`):

- **prodesk** (server): auto-upgrade, hardening, healthchecks-runitor, home-assistant, impermanence, initrd-ssh, static-ip, sudo-ssh-agent, restic-b2, tailscale-server, syncthing-server, samba
- **desktop**: desktop, docker, gnome, keyd, restic-b2, tailscale-client, syncthing-client, initrd-ssh, static-ip, bridge-networking, vfio-gpu, looking-glass, virt-manager, wol-vm-start, yubikey
- **thinkpad**: desktop, docker, gnome, keyd, restic-b2, tailscale-client, syncthing-client, fprintd, networkmanager, yubikey

- `modules/nixos/common.nix` — foundation: imports `options`, `base`, `dotfiles`, `hardening-common`, `secure-boot`, `ssh`, disko, lanzaboote (all hosts import this)
- `modules/nixos/options.nix` — shared `local.*` options consumed by 2+ unrelated modules (`user`, `sshKey`, `net`)
- `modules/nixos/base.nix` — universal: nix settings + weekly GC, user, btrfs scrub
- `modules/nixos/dotfiles.nix` — systemd oneshot that checks out dotfiles into user home
- `modules/nixos/ssh.nix` — sshd config (key-only, no root, no TCP/stream forwarding, idle drop)
- `modules/nixos/hardening-common.nix` — universal hardening (sysctl, kptr, yama, wheel-only nix/sudo)
- `modules/nixos/secure-boot.nix` — lanzaboote secure boot (all hosts import this)
- `modules/nixos/hardening.nix` — server-only hardening (auditd, modprobe blacklist, martians) on top of hardening-common
- `modules/nixos/desktop.nix` — desktop baseline: pipewire, hardware, packages
- `modules/nixos/keyd.nix` — keyboard daemon (Caps Lock → Escape/Ctrl)
- `modules/nixos/docker.nix` — Docker daemon + lazydocker
- `modules/nixos/gnome/` — GNOME DE, dconf settings
- `modules/nixos/fprintd.nix` — fingerprint auth (hosts opt in)
- `modules/nixos/yubikey.nix` — pam_u2f, opensc (PIV), session lock on YubiKey removal
- `modules/nixos/sudo-ssh-agent.nix` — tap-to-sudo via pam_rssh over forwarded SSH agent
- `modules/nixos/restic-b2.nix` — Backblaze B2 backups with TPM-sealed creds; bucket derived from hostname (`murar8-${host}-restic`), paths/excludes via `local.restic.*`
- `modules/nixos/healthchecks-runitor.nix` — systemd timer (every 15 min) pinging healthchecks.io via `runitor`; project ping key TPM-sealed at `/etc/healthchecks/ping-key.cred` (prodesk: `/persist/etc/healthchecks/ping-key.cred` via impermanence), slug derived from `config.networking.hostName`. Check is declared in `tofu/healthchecks.tf`
- Networking (pick one): `static-ip.nix` (server), `bridge-networking.nix` (desktop), `networkmanager.nix` (laptop)
- Tailscale: `tailscale-server.nix` (subnet routing, exit node) / `tailscale-client.nix` (operator mode)
- Syncthing: `syncthing-server.nix` (system service, GUI on LAN, persistence) / `syncthing-client.nix` (user service)
- `modules/nixos/home-assistant/` — Home Assistant + lovelace dashboard
- `modules/nixos/samba.nix` — Samba file sharing
- `modules/nixos/impermanence/` — btrfs root rollback, persistence base dirs
- `modules/nixos/initrd-ssh.nix` — initrd SSH for remote disk unlock
- `modules/nixos/auto-upgrade.nix` — automatic flake-based upgrades
- Virtualization: `vfio-gpu.nix`, `looking-glass.nix`, `virt-manager/`, `wol-vm-start/`
- Only `common.nix` may import other modules; all other modules are wired by hosts explicitly

## Code Style

- Modules that take no args use `_:` not `{ ... }:` (statix enforces this)
- Shell scripts live alongside their `.nix` module, loaded via `writeShellApplication` + `builtins.readFile`

## Module Conventions

- **File splits**: one module = one host opt-in capability. Single `.nix` until you need a non-`.nix` asset (script/data) or there's a self-contained chunk worth lifting. `lib/` for pure helpers — no "utility" modules. Promote into `common.nix` only when all hosts already import explicitly.
- **Options vs `let` vs inline**: promote to `lib.mkOption` only on (a) **variance** — 2+ hosts need different values, (b) **cross-module** — 2+ unrelated modules read it, or (c) **per-host identity/secret** — YubiKey keys, host SSH keys, B2 creds. Otherwise inline (single use), `let` (multi-use in module), or `let` in a dir's `default.nix` / `lib/` (cross-module reuse). "User-facing knob" alone isn't enough.
- **Where options live**: module-specific options live in the module that reads them. `options.nix` only holds options consumed by 2+ unrelated modules or the host.
- **Don't pre-split, pre-option, or pre-promote.** Wait for the second caller, the second host, or actual variance.

## Prodesk Gotchas

- **Impermanence**: root btrfs subvol wiped every boot; any new service storing state on prodesk needs a persistence entry in `hosts/prodesk/configuration.nix`
- **Persistence ownership**: service-specific persistence (state dirs, credential dirs) lives in the host that imports impermanence — service modules must not declare `environment.persistence` so they stay portable to non-impermanence hosts. The `impermanence` module itself owns the foundational persistence (system dirs, ssh host keys, user dotdirs). Modules still own their config, firewall, and hardening.
- LUKS uses 4096-byte sectors; partition size must be multiple of 8 x 512-byte sectors or `cryptsetup resize` fails
- TPM2 modules (`tpm_tis`, `tpm_crb`) must be in `initrd.availableKernelModules` — SATA boots faster than USB, causing TPM race
- TPM2 re-enroll after SB key changes: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks`
- Restic creds are TPM-sealed to PCR 7 at `/etc/restic/*.cred` (prodesk: `/persist/etc/restic/*.cred` via impermanence) — must be re-sealed after SB key changes (same trigger as LUKS); bootstrap with `systemd-creds encrypt --with-key=tpm2 --tpm2-pcrs=7` for `repo-password.cred` and `b2-env.cred` (B2_ACCOUNT_ID/B2_ACCOUNT_KEY). Each host has its own B2 bucket + credentials. Keep repo passwords in Bitwarden — losing one makes that host's B2 backups unrecoverable.
- Healthchecks project ping key is TPM-sealed at `/persist/etc/healthchecks/ping-key.cred` (PCR 7) — must be re-sealed after SB key changes (same trigger as restic/LUKS). Module pings via `runitor -ping-key <key> -slug ${hostname}-heartbeat`; the slug must match the check's slug in HC.io (auto-derived from the check `name` in `tofu/healthchecks.tf`, currently `prodesk-heartbeat`). Bootstrap: copy the project Ping key from HC.io (Project Settings → API Access → Ping key) into `systemd-creds encrypt --with-key=tpm2 --tpm2-pcrs=7 - /persist/etc/healthchecks/ping-key.cred`.
- YubiKey session-lock udev rule matches `ENV{PRODUCT}=="1050/407/*"` (YubiKey 5 OTP+FIDO+CCID) — swapping models requires updating the rule
- Tap-to-sudo uses two FIDO2 sk keys on one YubiKey (`yubikeyLoginSshKey` no-touch, `yubikeySudoSshKey` touch); do not raise sudo `timestamp_timeout` or you defeat the tap
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

## OpenTofu

- `tofu/` manages Tailscale ACLs, B2 buckets, and healthchecks.io checks
- Apply runs only in CI (`.github/workflows/tofu.yml`): PRs run `tofu plan`, push to `main` runs `tofu apply` — never apply locally

## Tailscale Gotchas

- Subnet routes need an ACL grant in `tofu/tailscale.tf` (advertise ≠ allow)
- `extraUpFlags` only runs on first login; use `extraSetFlags` for persistent settings
- Tailscale subnet routing captures LAN traffic to .130 — disconnect TS for Samba access

## Nix Gotchas

- New `.nix` files must be `git add`ed before build/check
- `nixos-rebuild` prompts for sudo password / YubiKey tap — requires interactive terminal, Claude Code cannot run rebuilds
- `boot.initrd.network.ssh` is the correct initrd SSH option even with `boot.initrd.systemd.enable = true`
- statix enforces merging repeated attrset keys
- nil pre-commit hook has `denyWarnings = true`
- `writeShellApplication` adds shebang + `set -euo pipefail` — don't duplicate
- systemd service PATH only has systemd bin — use absolute nix store paths in `ExecStart`
- `boot.initrd.systemd.network` carries into booted system via systemd-networkd
- envfs + systemd initrd + fresh install = boot failure (systemd v257); workaround in desktop.nix
- SSH agent forwarding must stay enabled — Bitwarden agent keys forwarded to prodesk for git
- `pkexec` does not work for `nixos-rebuild` — use `--sudo` flag instead
- Remote rebuild must always use `--build-host` (nix-copy-closure fails with "lacks a signature")
- SSH keys are in Bitwarden agent (no files on disk) — use `ssh-add -L | grep lnzmrr` to extract public key
- Prodesk has no `rsync`/`parted`/`sgdisk` — use `nix-shell -p <pkg>` or `nix run`

## Installer Pitfalls

- Installer tmpfs too small for flake eval — use standalone `disko --mode destroy,format,mount` instead of `--flake`
- nixos-anywhere can hit I/O errors on installer — power cycle fixes it
- systemd-initrd hides LUKS prompt on this console — use traditional initrd for interactive unlock
- Exclude `result/`, `.direnv/` when copying config to installer; include `.git/` for flake eval
