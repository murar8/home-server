#!/usr/bin/env bash
set -euo pipefail

# Used as services.restic.backups.b2.package. Loads B2 creds from systemd
# LoadCredentialEncrypted, then exec's restic.
# CAP_DAC_READ_SEARCH is supplied via the unit's AmbientCapabilities.

# `$(< file)` reads file content directly without forking or piping — the
# SystemCallFilter denies @ipc (covers pipe/pipe2) since restic itself doesn't need it.
B2_ACCOUNT_ID=$(<"$CREDENTIALS_DIRECTORY/b2-account-id")
B2_ACCOUNT_KEY=$(<"$CREDENTIALS_DIRECTORY/b2-account-key")
export B2_ACCOUNT_ID B2_ACCOUNT_KEY
exec restic "$@"
