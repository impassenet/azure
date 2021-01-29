#!/bin/sh

#-----------------------------------------------------------------------------------------------------------------
# Description: Script post installation BDD SPIE
# Createur: Clegrand@integra.fr
# Version: 1.0
# Puppet Agent version: 5.X
# OS support: Redhat 7 latest (Actuellement 7.9)
#-----------------------------------------------------------------------------------------------------------------

# variables
host=$1
ip=10.211.122.132
device=sdc

# Sources puppet 5
puppet_version_redhat7="https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm"




# Configuration hosts
cat >> /etc/hosts<<EOF
${ip} kickstart.itc.integra.fr
${ip} kickstart2.itc.integra.fr
${ip} puppet5.itc.integra.fr
EOF

# Creation dossier pour les volumes groupes
mkdir /production
mkdir /u01
mkdir /orasave

#-------------------------------------------
# Installation puppet agentt
#-------------------------------------------
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -ivh $puppet_version_redhat7
yum install puppet-agent  -y  --nogpgcheck   

#-------------------------------------------
# Post configuration
#-------------------------------------------

# Creation partition LVM production
echo "n
p
1


w" | fdisk "/dev/${device}"
pvcreate -f "/dev/${device}1"
vgcreate VolGroup01 "/dev/${device}1"

# creation volumes logiques
lvcreate -n u01 -L 3G VolGroup01
lvcreate -n orasave -L 50G VolGroup01
lvcreate -l +100%FREE -n PRODUCTION VolGroup01
mkfs.xfs /dev/mapper/VolGroup01-PRODUCTION
mkfs.xfs /dev/mapper/VolGroup01-orasave
mkfs.xfs /dev/mapper/VolGroup01-PRODUCTION
echo '/dev/mapper/VolGroup01-PRODUCTION  /production xfs defaults,noatime 0 2' >> /etc/fstab
echo '/dev/mapper/VolGroup01-u01  /u01 xfs defaults,noatime 0 2' >> /etc/fstab
echo '/dev/mapper/VolGroup01-orasave  /orasave xfs defaults,noatime 0 2' >> /etc/fstab

# creation swap
lvcreate -n swap -L 4G VolGroup01
mkswap /dev/mapper/VolGroup01-swap
echo '/dev/mapper/VolGroup01-swap swap                    swap    defaults        0 0' >> /etc/fstab

mount -a

# Desactivation SELINUX
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config

# Desactivation IPV6

echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf

# Configfuration puppet et lancement du service

cat > /etc/puppetlabs/puppet/puppet.conf<<EOF
[agent]
server      = puppet5.itc.integra.fr
certname    = ${host}
masterport  = 8141
report_port = 8141
noop        = false
EOF


# start systemctl puppet
systemctl start puppet

exit

