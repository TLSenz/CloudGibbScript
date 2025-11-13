#!/bin/bash

echo "-----------------------------------------------------"
echo "Welcome to the Installation of a Storage Pool and LXD"
echo "-----------------------------------------------------"

if [[ $EUID -ne 0 ]]; then
   echo "Please run as root."
   exit 1
fi

echo ""
lsblk
echo ""
echo "Please Select the Disk you want to Format"
echo ""

read -p "Please Enter your Disk, just know that it everything on it will be Deleted: " disk

echo "Creating new Partition"
echo -e "n\np\n1\n\n+1G\nw" | fdisk /dev/${disk}
echo "Created new Partition"
echo "Formating"

sudo mkfs.ext4 /dev/${disk}
sudo mkdir /storage3

UUID=$(blkid -s UUID -o value "$PARTITION")

cp /etc/fstab /etc/fstab.break
echo "Created backup of fstab"
echo "/dev/disk/by-uuid/$UUID $MOUNT_POINT ext4 defaults,auto 0 2" >> /etc/fstab
echo "Added entry to /etc/fstab"

systemctl daemon-reload
mount -a

if mountpoint -q "$MOUNT_POINT"; then
  echo "Successfull Mounted Endpoint"

else
  echo "Something went wrong with mounting"
