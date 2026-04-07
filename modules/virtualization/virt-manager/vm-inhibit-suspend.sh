#!/usr/bin/env bash

# Libvirt qemu hook — inhibits system sleep while a VM is running.
# Called by libvirt as: hook <guest> <operation> <sub-operation> <extra>
# https://libvirt.org/hooks.html

GUEST="$1"
OPERATION="$2"

case "$OPERATION" in
started | reconnect)
  systemctl start "vm-inhibit-suspend@${GUEST}.service"
  ;;
stopped)
  systemctl stop "vm-inhibit-suspend@${GUEST}.service"
  ;;
esac
