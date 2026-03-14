#!/usr/bin/env bash
set -euo pipefail

mkdir -p /mnt
mount -o subvol=/ /dev/mapper/cryptroot /mnt

for subvolume in $(btrfs subvolume list -o /mnt/root | cut -f9 -d' '); do
  echo "deleting /$subvolume ..."
  btrfs subvolume delete "/mnt/$subvolume"
done

echo "deleting /root ..."
btrfs subvolume delete /mnt/root

echo "restoring blank /root ..."
btrfs subvolume snapshot /mnt/root-blank /mnt/root

echo "restoring /etc/machine-id ..."
mkdir -p /mnt/root/etc
cp /mnt/persist/etc/machine-id /mnt/root/etc/machine-id

umount /mnt
