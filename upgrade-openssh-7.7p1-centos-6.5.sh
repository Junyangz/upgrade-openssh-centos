#!/bin/bash
# Copyright © 2018 Junyangz
# For CRS2-Centos 6.5 with OpenSSH_5.3p1, OpenSSL 1.0.1e-fips 11 Feb 2013
cd
mkdir openssh && cd openssh
timestamp=$(date +%s)
if [ ! -f openssh-7.7p1-RPMs.tar.gz ]; then wget https://github.com/Junyangz/upgrade-openssh-7.7p1-centos/releases/download/0.1/openssh-7.7p1-RPMs.tar.gz; fi;
tar zxvf openssh-7.7p1-RPMs.tar.gz
cp /etc/pam.d/sshd pam-ssh-conf-$timestamp
rpm -e --nodeps `rpm -qa | grep openssh-askpass`
rpm -U *.rpm
yes | cp pam-ssh-conf-$timestamp /etc/pam.d/sshd
#sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart
echo "New version upgrades as to lastest:" && $(ssh -V)
