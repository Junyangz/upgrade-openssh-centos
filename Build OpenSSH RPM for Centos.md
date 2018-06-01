# Build OpenSSH RPM for Centos

```bash
yum install -y pam-devel rpm-build rpmdevtools zlib-devel openssl-devel krb5-devel gcc
mkdir -p ~/rpmbuild/SOURCES && cd ~/rpmbuild/SOURCES

wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.7p1.tar.gz
wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.7p1.tar.gz.asc
# # verify the file

# update the pam sshd from the one included on the system
# the default provided doesn't work properly on centos 6.5
tar zxvf openssh-7.7p1.tar.gz
cp /etc/pam.d/sshd openssh-7.7p1/contrib/redhat/sshd.pam
mv openssh-7.7p1.tar.gz{,.old}
tar zcpf openssh-7.7p1.tar.gz openssh-7.7p1
cd
tar zxvf ~/rpmbuild/SOURCES/openssh-7.7p1.tar.gz openssh-7.7p1/contrib/redhat/openssh.spec
# edit the specfile
cd openssh-7.7p1/contrib/redhat/
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec
#if encounter build error with the follow line, comment it.
sed -i -e "s/PreReq: initscripts >= 5.00/#PreReq: initscripts >= 5.00/g" openssh.spec
rpmbuild -ba openssh.spec
```

## Reference

[Build OpenSSH RPM for Centos](http://www.arvinep.com/2015/12/building-rpm-openssh-71p1-on-rhelcentos.html)
[gist](https://gist.github.com/tjheeta/654a246d18fea65b2da0)