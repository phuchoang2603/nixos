# New NAS disk

Skip this guide when reusing the existing application-data disk.

On TrueNAS, create:

| Setting | Value |
| --- | --- |
| Zvol | `storage/container`, 128 GiB |
| Portal | `10.69.1.102:3260` |
| Target IQN | `iqn.2005-10.org.freenas.ctl:container` |
| Extent | Device extent for the zvol, mapped as LUN 0 |
| Allowed initiator | `iqn.2026-10.local.nixos:nixos-server` |
| NFS export | `/mnt/storage/media` |

In the server installer root shell, connect to the LUN:

```bash
nix-shell -p openiscsi e2fsprogs nano
mkdir -p /etc/iscsi
printf '%s\n' 'InitiatorName=iqn.2026-10.local.nixos:nixos-server' \
  > /etc/iscsi/initiatorname.iscsi
modprobe iscsi_tcp
iscsid -c /dev/null
iscsiadm -m discovery -t sendtargets -p 10.69.1.102:3260
iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:container \
  -p 10.69.1.102:3260 --login
udevadm settle
iscsiDisk=/dev/disk/by-path/ip-10.69.1.102:3260-iscsi-iqn.2005-10.org.freenas.ctl:container-lun-0
lsblk -o NAME,SIZE,FSTYPE,UUID "$iscsiDisk"
```

**The next command erases the LUN. Run it only on a new, empty disk.**

```bash
mkfs.ext4 -L container "$iscsiDisk"
blkid -s UUID -o value "$iscsiDisk"
cd /mnt/etc/nixos
nano modules/server/storage.nix
```

Set the ext4 `device` to `/dev/disk/by-uuid/` followed by the printed UUID.
NixOS mounts it at `/mnt/storage/container` and mounts media at
`/mnt/storage/media`. NAS address and paths are in `modules/server/lib.nix`.

Continue with [server boot decryption and installation](server.md#boot-decryption)
in this same root shell.
