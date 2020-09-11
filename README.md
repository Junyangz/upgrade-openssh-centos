# Upgrade OpenSSH for CentOS

---

## Usage

```bash
bash <(curl -sSL https://github.com/Junyangz/upgrade-openssh-centos/raw/master/build-RPMs-OpenSSH-CentOS.sh) \
    --version 8.3p1  \
    --output_rpm_dir /tmp/tmp.dirs \
    --upgrade_now yes
```

## Build RPMs

```bash
build_RPMs() {
    local output_rpm_dir="${1}"
    yum install -y pam-devel rpm-build rpmdevtools zlib-devel openssl-devel krb5-devel gcc wget libx11-dev gtk2-devel libXt-devel
    mkdir -p ~/rpmbuild/SOURCES && cd ~/rpmbuild/SOURCES
    
    wget -c https://mirrors.tuna.tsinghua.edu.cn/OpenBSD/OpenSSH/portable/openssh-${version}.tar.gz
    wget -c https://mirrors.tuna.tsinghua.edu.cn/OpenBSD/OpenSSH/portable/openssh-${version}.tar.gz.asc
    wget -c https://mirrors.tuna.tsinghua.edu.cn/slackware/slackware64-current/source/xap/x11-ssh-askpass/x11-ssh-askpass-1.2.4.1.tar.gz

    tar zxvf openssh-${version}.tar.gz
    yes | cp /etc/pam.d/sshd openssh-${version}/contrib/redhat/sshd.pam
    mv openssh-${version}.tar.gz{,.orig}
    tar zcpf openssh-${version}.tar.gz openssh-${version}
    cd
    tar zxvf ~/rpmbuild/SOURCES/openssh-${version}.tar.gz openssh-${version}/contrib/redhat/openssh.spec

    cd openssh-${version}/contrib/redhat/ && chown root.root openssh.spec
    sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
    sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
    sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec
    sed -i -e "s/PreReq: initscripts >= 5.00/#PreReq: initscripts >= 5.00/g" openssh.spec
    sed -i -e "s/BuildRequires: openssl-devel < 1.1/#BuildRequires: openssl-devel < 1.1/g" openssh.spec
    sed -i -e "/check-files/ s/^#*/#/"  /usr/lib/rpm/macros

    rpmbuild -ba openssh.spec
    cd /root/rpmbuild/RPMS/x86_64/
    tar zcvf ${output_rpm_dir}/openssh-${version}-RPMs.el${rhel_version}.tar.gz openssh*
    rm -rf ~/rpmbuild ~/openssh-${version}
}
```

---

## Update with RPMs

```bash
upgrade_openssh() {
    local temp_dir="$(mktemp -d)"
    local output_rpm_dir="$1"
    trap "rm -rf ${temp_dir}" EXIT
    pushd "${temp_dir}"

    timestamp=$(date +%s)
    if [ ! -f ${output_rpm_dir}/openssh-${version}-RPMs.el${rhel_version}.tar.gz ]; then
        echo "${output_rpm_dir}/openssh-${version}-RPMs.el${rhel_version}.tar.gz not exist"
        exit 1
    fi
    cp ${output_rpm_dir}/openssh-${version}-RPMs.el${rhel_version}.tar.gz ./
    tar zxf openssh-${version}-RPMs.el${rhel_version}.tar.gz
    cp /etc/pam.d/sshd pam-ssh-conf-${timestamp}
    rpm -U *.rpm
    mv /etc/pam.d/sshd /etc/pam.d/sshd_${timestamp}
    yes | cp pam-ssh-conf-${timestamp} /etc/pam.d/sshd
    sed -i '/PermitRootLogin yes/ s/^#*//'  /etc/ssh/sshd_config
    chmod 600 /etc/ssh/ssh*
    /etc/init.d/sshd restart
    echo "New version upgrades as to lastest:" ; $(ssh -V)
}
```

---

More information please refer `build-RPMs-OpenSSH-CentOS.sh` script.

The [release page](https://github.com/Junyangz/upgrade-openssh-centos/releases) has some RPMs that I built, feel free to use it.

## Reference

[Build OpenSSH RPM for Centos](http://www.arvinep.com/2015/12/building-rpm-openssh-71p1-on-rhelcentos.html)

[gist](https://gist.github.com/tjheeta/654a246d18fea65b2da0)
