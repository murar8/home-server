#!/usr/bin/env bash
set -u

# WoL magic packet = 6×0xFF then 16× target MAC (6 bytes each), 102 bytes total.
# Based on https://serverfault.com/questions/474199
socat -u UDP-RECV:9,reuseaddr STDOUT | # -u: unidirectional, UDP-RECV: listen UDP port 9
  stdbuf -o0 xxd -c 6 -p |             # -c 6: 6 bytes/line, -p: plain hex (one MAC-width chunk)
  stdbuf -o0 uniq |                    # collapse 16 identical MAC repetitions into one line
  stdbuf -o0 grep -v 'ffffffffffff' |  # drop the 6×0xFF header, leaving only the target MAC
  while read -r REPLY; do              # stdbuf -o0: unbuffered stdout for immediate processing
    mac="${REPLY:0:2}:${REPLY:2:2}:${REPLY:4:2}:${REPLY:6:2}:${REPLY:8:2}:${REPLY:10:2}"
    for vm in $(virsh -c qemu:///system list --all --name); do
      [ -z "$vm" ] && continue
      for vmmac in $(virsh -c qemu:///system dumpxml "$vm" | grep "mac address" | awk -F\' '{ print $2}'); do
        if [ "$vmmac" = "$mac" ]; then
          echo "WoL received for $vm ($mac)"
          state=$(virsh -c qemu:///system domstate "$vm")
          case "$state" in
          "paused") virsh -c qemu:///system resume "$vm" ;;
          "shut off") virsh -c qemu:///system start "$vm" ;;
          esac
        fi
      done
    done
  done
