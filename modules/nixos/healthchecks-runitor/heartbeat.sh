#!/usr/bin/env bash
set -euo pipefail

# Pings healthchecks.io. Slug + ping-key resolved at runtime so the script body
# is a static blob writeShellApplication can hand to shellcheck.

runitor \
  -ping-key "$(cat "$CREDENTIALS_DIRECTORY/ping-key")" \
  -slug "$HC_SLUG" \
  -- true
