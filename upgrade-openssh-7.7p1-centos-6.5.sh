#!/bin/bash
# Copyright © 2018 Junyangz
cd
mkdir openssh && cd openssh
timestamp=$(date +%s)
if [ ! -f openssh-7.7p1-RPMs.zip ]; then wget https://github.com/Junyangz/upgrade-openssh-7.7p1-centos/releases/download/0.1/openssh-7.7p1-RPMs.zip; fi;
unzip -o openssh-7.7p1-RPMs.zip
cp /etc/pam.d/sshd pam-ssh-conf-$timestamp
rpm -U *.rpm
yes | cp pam-ssh-conf-$timestamp /etc/pam.d/sshd
#sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart