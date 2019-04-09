#!/bin/bash
# Build OpenSSH RPM for CentOS 6.5
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

if [ ! -x $1 ]; then
    version=$1
else
    echo "Usage: sh $0 {openssh-version}(default is 7.9p1)"
    echo "version not provided '7.9p1' will be used."
    while true; do
        read -p "Do you want to continue (Y/N)? " yn
        case $yn in
            [Yy]* ) version="7.9p1"; break;;
            [Nn]* ) exit ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

function build_RPMs(){
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
    if [ `rpm -q --queryformat '%{VERSION}' centos-release` -eq "7" ]; then
        sed -i -e "s/BuildRequires: openssl-devel < 1.1/#BuildRequires: openssl-devel < 1.1/g" openssh.spec
    fi
    rpmbuild -ba openssh.spec
    cd /root/rpmbuild/RPMS/x86_64/
    tar zcvf openssh-${version}-RPMs.tar.gz openssh*
    mv openssh-${version}-RPMs.tar.gz ~ && rm -rf ~/rpmbuild ~/openssh-${version}
    # openssh-${version}-RPMs.tar.gz ready for use.

}

function upgrade_openssh(){
    cd /tmp
    mkdir openssh && cd openssh
    timestamp=$(date +%s)
    if [ ! -f ~/openssh-${version}-RPMs.tar.gz ]; then 
        echo "~/openssh-${version}-RPMs.tar.gz not exist" 
        exit 1
    fi
    cp ~/openssh-${version}-RPMs.tar.gz ./
    tar zxf openssh-${version}-RPMs.tar.gz 
    cp /etc/pam.d/sshd pam-ssh-conf-${timestamp}
    rpm -U *.rpm
    mv /etc/pam.d/sshd /etc/pam.d/sshd_${timestamp}
    yes | cp pam-ssh-conf-${timestamp} /etc/pam.d/sshd
    #sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
    if [ `rpm -q --queryformat '%{VERSION}' centos-release` -eq "7" ]; then
        chmod 600 /etc/ssh/ssh*
        systemctl restart sshd.service
    else
        /etc/init.d/sshd restart
    fi
    cd
    rm -rf /tmp/openssh
    echo "New version upgrades as to lastest:" && $(ssh -V)
}

function main(){
    if [ -f ~/openssh-${version}-RPMs.tar.gz ];then
        echo "openssh-${version}-RPMs.tar.gz file already exist, do you want to build again?"
        while true; do
            read -p "Continue build (Y/N)? " yn
            case $yn in
                [Yy]* ) build_RPMs; break;;
                [Nn]* ) break ;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    else
        echo "Start build openssh-${version}-RPMs ..."
        sleep 1s
        build_RPMs
    fi

    while true; do
        read -p "Do you want to install update now (Y/N)? " yn
        case $yn in
            [Yy]* ) upgrade_openssh; break;;
            [Nn]* ) exit ;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

main