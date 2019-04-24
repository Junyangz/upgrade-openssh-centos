# Upgrade OpenSSH for CentOS

---

## Build RPMs

```bash
rhel_version=`rpm -q --queryformat '%{VERSION}' centos-release`
version="8.0p1"
yum install -y pam-devel rpm-build rpmdevtools zlib-devel openssl-devel krb5-devel gcc wget
mkdir -p ~/rpmbuild/SOURCES && cd ~/rpmbuild/SOURCES

wget -c https://mirrors.tuna.tsinghua.edu.cn/OpenBSD/OpenSSH/portable/openssh-${version}.tar.gz
wget -c https://mirrors.tuna.tsinghua.edu.cn/OpenBSD/OpenSSH/portable/openssh-${version}.tar.gz.asc
wget -c https://mirrors.tuna.tsinghua.edu.cn/slackware/slackware64-current/source/xap/x11-ssh-askpass/x11-ssh-askpass-1.2.4.1.tar.gz
# # verify the file

# update the pam sshd from the one included on the system
# the default provided doesn't work properly on CentOS 6.5
tar zxvf openssh-${version}.tar.gz
yes | cp /etc/pam.d/sshd openssh-${version}/contrib/redhat/sshd.pam
mv openssh-${version}.tar.gz{,.orig}
tar zcpf openssh-${version}.tar.gz openssh-${version}
cd
tar zxvf ~/rpmbuild/SOURCES/openssh-${version}.tar.gz openssh-${version}/contrib/redhat/openssh.spec
# edit the specfile
cd openssh-${version}/contrib/redhat/
chown root.root openssh.spec
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec
#if encounter build error with the follow line, comment it.
sed -i -e "s/PreReq: initscripts >= 5.00/#PreReq: initscripts >= 5.00/g" openssh.spec
#CentOS 7
if [ "${rhel_version}" -eq "7" ]; then
    sed -i -e "s/BuildRequires: openssl-devel < 1.1/#BuildRequires: openssl-devel < 1.1/g" openssh.spec
fi
rpmbuild -ba openssh.spec
cd /root/rpmbuild/RPMS/x86_64/
tar zcvf openssh-${version}-RPMs.el${rhel_version}.tar.gz openssh*
mv openssh-${version}-RPMs.el${rhel_version}.tar.gz ~ && rm -rf ~/rpmbuild ~/openssh-${version}
# openssh-${version}-RPMs.el${rhel_version}.tar.gz ready for use.
```

---

## Update with RPMs

```bash
cd /tmp
mkdir openssh && cd openssh
timestamp=$(date +%s)
if [ ! -f ~/openssh-${version}-RPMs.el${rhel_version}.tar.gz ]; then 
    echo "~/openssh-${version}-RPMs.el${rhel_version}.tar.gz not exist" 
    exit 1
fi
cp ~/openssh-${version}-RPMs.el${rhel_version}.tar.gz ./
tar zxf openssh-${version}-RPMs.el${rhel_version}.tar.gz 
cp /etc/pam.d/sshd pam-ssh-conf-${timestamp}
rpm -U *.rpm
mv /etc/pam.d/sshd /etc/pam.d/sshd_${timestamp}
yes | cp pam-ssh-conf-${timestamp} /etc/pam.d/sshd
#sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
if [ "${rhel_version}" -eq "7" ]; then
    chmod 600 /etc/ssh/ssh*
    systemctl restart sshd.service
else
    /etc/init.d/sshd restart
fi
cd
rm -rf /tmp/openssh
echo "New version upgrades as to lastest:" && $(ssh -V)
```

---

More information please refer `build-RPMs-OpenSSH-CentOS.sh` script.

The [release page](https://github.com/Junyangz/upgrade-openssh-centos/releases) has some RPMs that I built, feel free to use it.

## Reference

[Build OpenSSH RPM for Centos](http://www.arvinep.com/2015/12/building-rpm-openssh-71p1-on-rhelcentos.html)
[gist](https://gist.github.com/tjheeta/654a246d18fea65b2da0)
