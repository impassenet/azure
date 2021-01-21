#!/bin/sh

#-----------------------------------------------------------------------------------------------------------------
# Description: Script post installation puppet sur Azure
# Createur: Clegrand@integra.fr
# Version: 1.1
# Puppet Agent version: 5.X
# OS support: Centos 7.6 (Et superieur) - Centos 8.X - Redhat 7.6 (Et superieur)  - Redhat 8.X - Debian 10.X - Ubuntu 18.X
#-----------------------------------------------------------------------------------------------------------------

# variables
host=$1
ip=$2
device=$3

# Sources puppet 5
puppet_version_redhat7="https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm"
puppet_version_redhat8="https://yum.puppetlabs.com/puppet5/puppet5-release-el-8.noarch.rpm"
puppet_version_debian10="https://apt.puppetlabs.com/puppet5-release-buster.deb"
puppet_version_debian9="https://apt.puppetlabs.com/puppet5-release-stretch.deb"
puppet_version_ubuntu18="https://apt.puppetlabs.com/puppet5-release-bionic.deb"
REV="unknown"



# Configuration hosts
cat >> /etc/hosts<<EOF
${ip} kickstart.itc.integra.fr
${ip} kickstart2.itc.integra.fr
${ip} puppet5.itc.integra.fr
EOF

# Creation dossier production
mkdir /production

#-------------------------------------------
# Installation puppet agent CentOS et Redhat
#-------------------------------------------

if [ -f /etc/redhat-release ] ; then
    upgrade_cmd='/bin/yum update -y'
    update_cmd="echo 'update auto sur famille RHEL'"
    REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    if [[ $REV == "7"* ]] ; then
        # Installation repo epel et puppet
            rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            rpm -ivh $puppet_version_redhat7
            yum install puppet-agent  -y  --nogpgcheck   
        # installation dependances fusion inventory
        #    yum localinstall http://kickstart.itc.integra.fr/pub/IAOS/PUPPET5/packages/perl-Crypt-DES-2.05-20.el7.x86_64.rpm http://kickstart.itc.integra.fr/pub/IAOS/PUPPET5/packages/perl-File-Which-1.09-12.el7.noarch.rpm http://kickstart/pub/IAOS/PUPPET5/packages/perl-File-Copy-Recursive-0.38-14.el7.noarch.rpm        
    elif [[ $REV == "8"* ]] ; then
            # Installation repo epel et puppet
            rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            rpm -ivh $puppet_version_redhat8
            yum install puppet-agent lvm2 sssd -y  --nogpgcheck       
    else
            echo '[ERROR] RHEL Version not recognized.'
            exit 1
    fi


#-------------------------------------------
# Installation puppet agent + prerequis Debian - Ubuntu
#-------------------------------------------

elif [ -f /etc/os-release ] ; then
    upgrade_cmd='/usr/bin/apt-get upgrade -y'
    update_cmd='/usr/bin/apt-get update -y'
    REV=`cat /etc/os-release | grep '^VERSION_CODENAME' | awk -F=  '{ print $2 }'`
    if [ $REV = bionic ] ; then
        wget $puppet_version_ubuntu18
        dpkg -i puppet5-release-bionic.deb
        apt-get update && apt-get install gnupg puppet-agent -y
    elif [ $REV = stretch ] ; then
        wget $puppet_version_debian9
        dpkg -i puppet5-release-stretch.deb
        apt-get update && apt-get install gnupg puppet-agent -y
    elif [ $REV = buster ] ; then
        wget $puppet_version_debian10
        dpkg -i puppet5-release-buster.deb
        apt-get update &&  apt-get install gnupg lvm2 xfsprogs sssd chrony puppet-agent -y
        apt-get dist-upgrade -y
    else
        echo '[ERROR] RHEL Version not recognized.'
        exit 1
    fi
else
    echo '[ERROR] Script only for Debian and RedHat families.'
    exit 1
fi

# Creation partition LVM production
echo "n
p
1


w" | fdisk "/dev/${device}"
pvcreate -f "/dev/${device}1"
vgcreate VolGroup01 "/dev/${device}1"
lvcreate -l +100%FREE -n PRODUCTION VolGroup01
mkfs.xfs /dev/mapper/VolGroup01-PRODUCTION
echo '/dev/mapper/VolGroup01-PRODUCTION  /production xfs defaults,noatime 0 2' >> /etc/fstab
mount /production

# Configfuration puppet et lancement du service

cat > /etc/puppetlabs/puppet/puppet.conf<<EOF
[agent]
server      = puppet5.itc.integra.fr
certname    = ${host}
masterport  = 8141
report_port = 8141
noop        = false
EOF


# Run puppet deux fois suite a erreur sssd
#/opt/puppetlabs/puppet/bin/puppet agent -t 2>/dev/null
systemctl start puppet

exit

