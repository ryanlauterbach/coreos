#!/bin/bash

mkdir -p /root/sda9
mount /dev/sda9 /mnt || exit 1
rsync -a /mnt/* /root/sda9
umount /dev/sda9

# delete sda9
sgdisk /dev/sda --delete=9

# create new /dev/sda9 partition (max size)
START=`sgdisk /dev/sda -f`
END=`sgdisk /dev/sda -E`
sgdisk /dev/sda --new=9:$START:$END --type=9:fd00
sleep 0.5
partprobe /dev/sda

# Remove partition table from sdb
sgdisk --clear -g /dev/sdb || exit 1

# create a partition sdb9 with the size of sda9
PARTDATA=( $(sgdisk -i 9 /dev/sda | grep 'Partition size' || exit 1) )
SECTORS=$(expr ${PARTDATA[2]} + 2048)
sgdisk /dev/sdb -a 2048 --new=9:2048:$SECTORS --type=9:fd00 || exit 1
sleep 0.5
partprobe /dev/sdb

# Create the RAID
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda9 /dev/sdb9
mkfs.ext4 -I 128 -L ROOT /dev/md0

# Copy the Data
mount /dev/md0 /mnt
rsync -a /root/sda9/* /mnt || exit 1

# set mdadm config and boot option
mkdir -p /mnt/etc/mdadm
cp mdadm.conf /mnt/etc/mdadm/mdadm.conf
mdadm --detail --scan >> /mnt/etc/mdadm/mdadm.conf
umount /mnt

# custom boot params
mkdir /oem_mnt
mount /dev/sda6 /oem_mnt
cp grub.cfg /oem_mnt
umount /oem_mnt


# Wait until resync is finished
# watch -n 1 cat /proc/mdstat
