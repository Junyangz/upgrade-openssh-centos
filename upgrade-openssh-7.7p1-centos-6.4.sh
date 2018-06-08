#!/bin/bash
# Copyright © 2018 Junyangz
# For CRS1-Centos 6.4 with OpenSSH_5.3p1, OpenSSL 1.0.0-fips 29 Mar 2010
if [ -f /etc/ssh/sshd_config.rpmnew ]; then 
	echo "New version upgrades as to lastest:" && $(ssh -V)
	exit 0
fi
cd /tmp/
# ansible all -m copy -a "src=/root/jyz/openssh-update/openssh-7.7p1-RPMs.tar.gz dest=/tmp/openssh-7.7p1-RPMs.tar.gz force=yes"
if [ ! -f openssh-7.7p1-RPMs.tar.gz ]; then exit 1; fi;
timestamp=$(date +%s)
tar zxvf openssh-7.7p1-RPMs.tar.gz
cd openssh
rpm -e --nodeps `rpm -qa |grep openssl-devel`
# update openssl
rpm -U openssl/*.rpm
# backup sshd
cp /etc/pam.d/sshd pam-ssh-conf-$timestamp
rpm -e --nodeps `rpm -qa | grep openssh-askpass`
rpm -U *.rpm
yes | cp pam-ssh-conf-$timestamp /etc/pam.d/sshd
/etc/init.d/sshd restart
cd
rm -rf /tmp/openssh /tmp/openssh-7.7p1-RPMs.tar.gz
echo "New version upgrades as to lastest:" && $(ssh -V)
