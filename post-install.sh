#!/bin/sh

#-----------------------------------------------------------------------------------------------------------------
# Description: Script post installation OVH
# Createur: Clegrand@integra.fr
# Version: 0.1
# OS support: Centos 7.6 (Et superieur) - Centos 8.X - Redhat 7.6 (Et superieur)  - Redhat 8.X - Debian 10.X - Ubuntu 18.X
#-----------------------------------------------------------------------------------------------------------------

# Update
yum update -y
yum install lvm2 -y
mkdir /production

# Creation partition LVM production
echo "n
p
1


w" | fdisk "/dev/sdb"
pvcreate -f "/dev/sdb1"
vgcreate VolGroup01 "/dev/sdb1"
lvcreate -l +100%FREE -n PRODUCTION VolGroup01
mkfs.xfs /dev/mapper/VolGroup01-PRODUCTION
echo '/dev/mapper/VolGroup01-PRODUCTION  /production xfs defaults,noatime 0 2' >> /etc/fstab
mount /production
