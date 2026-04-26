#!/usr/bin/env bash
set -euo pipefail

# Loaded by writeShellApplication and used as services.restic.backups.b2.package.
# Exports B2 creds from systemd LoadCredentialEncrypted, then exec's the
# capability-wrapped restic so it can read /persist on impermanence hosts.

B2_ACCOUNT_ID="$(cat "$CREDENTIALS_DIRECTORY/b2-account-id")"
B2_ACCOUNT_KEY="$(cat "$CREDENTIALS_DIRECTORY/b2-account-key")"
export B2_ACCOUNT_ID B2_ACCOUNT_KEY
exec /run/wrappers/bin/restic "$@"
