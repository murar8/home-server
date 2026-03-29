# NixOS Machines

## Claude Code Notes

- `pkexec` does not work for `nixos-rebuild` — use `--sudo` flag instead
  (pkexec changes cwd to /root and root can't access user's git repo)
- SSH keys are in Bitwarden agent (no files on disk) —
  use `ssh-add -L | grep lnzmrr` to extract public key;
  `ssh-copy-id` won't work, pipe to `authorized_keys` instead
- Remote rebuild must always use `--build-host` (nix-copy-closure
  fails with "lacks a signature")

## Commands

```sh
# Build locally (needs interactive terminal — use `!` prefix in Claude Code)
nixos-rebuild switch --flake .#thinkpad --sudo

# Rebuild remotely (needs interactive sudo)
nix run nixpkgs#nixos-rebuild -- switch --flake .#thinkpad \
  --target-host murar8@192.168.1.141 \
  --build-host murar8@192.168.1.141 \
  --sudo --ask-sudo-password

nixos-rebuild switch --flake .#debian \
  --target-host murar8@192.168.1.60 \
  --build-host murar8@192.168.1.60 \
  --ask-sudo-password

nix fmt                              # format
nix develop -c statix check .        # lint
nix develop -c nil diagnostics <file>
nix flake check                      # validate

# Compare derivations before/after refactoring
nix eval --raw .#nixosConfigurations.thinkpad.config.system.build.toplevel
nix store diff-closures <before> <after>
```

## TPM2 Re-enrollment

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto \
  --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
```

Re-enroll after Secure Boot key changes or "TPM policy does not match".

## Code Style

- Order attributes light-to-heavy: one-liners first,
  blocks last ("b shape")
- nixfmt `--strict` — formatting is fully deterministic
- Modules that take no args use `_:` not `{ ... }:`
  (statix enforces this)
- Shell scripts live alongside their `.nix` module
  (e.g. `wol-vm-start.nix` + `wol-vm-start.sh`),
  loaded via `writeShellApplication` + `builtins.readFile`

## GNOME / dconf

- `lockAll = true` forces system defaults over user dconf db
- dconf-reset service clears user db on login — logout/login
  after rebuild is sufficient; `dconf reset -f /` to force
- Extensions must be in both `systemPackages` and
  `enabled-extensions`; need logout/login after rebuild
- dash-to-dock: 3 hotkey families × 10 — all must be
  disabled to free Super+N keys
- Keybinding conventions: Super=focus, +Shift=move,
  +Ctrl=geometry, +Alt=workspace; hjkl ≡ arrows

## Nix Gotchas

- New `.nix` files must be `git add`ed before build/check
- statix enforces merging repeated attrset keys
- nil pre-commit hook has `denyWarnings = true`
- `writeShellApplication` adds shebang + `set -euo pipefail`
  — don't duplicate (keep shebang for treefmt shellcheck)
- systemd service PATH only has systemd bin — use absolute
  nix store paths for other binaries in `ExecStart`
- `boot.initrd.systemd.network` carries into booted system
  via systemd-networkd — use `networking.nameservers` for DNS
- envfs + systemd initrd + fresh install = boot failure
  (systemd v257); workaround in common.nix
- Downloaded binaries need `nix-ld` + `envfs`

## Hosts

- Debian: `debian` (192.168.1.60) — systemd-networkd, bridge
  networking, VFIO GPU passthrough, Looking Glass
- ThinkPad: `thinkpad` (192.168.1.141) — NetworkManager
- Server: `prodesk` (192.168.1.130, separate repo
  `github:murar8/home-server`)
- Tailscale subnet routing captures LAN traffic to .130 —
  disconnect TS for Samba access
