#!/usr/bin/env bash
# Copyright 2020, Junyangz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Tool to build OpenSSH RPM package for rhel6 & rhel7, not yet tested on rhel8.
# Build test pass on Centos 7 with openssh version {7.9p1,8.0p1,8.1p1,8.2p1,8.3p1}
#
# Usage:
#   bash <(curl -sSL https://github.com/Junyangz/upgrade-openssh-centos/raw/master/build-RPMs-OpenSSH-CentOS.sh) \
#       --version 8.3p1  \
#       --output_rpm_dir /tmp/tmp.dirs \
#       --upgrade_now yes
#
# Arguments:
#   version: The OpenSSH version to build, one of
#     the {7.9p1,8.0p1,8.1p1,8.2p1,8.3p1}.
#   output_rpm_dir: The output directory for rpm package to place.
#   upgrade_now: Whether install upgrade rpms now, yes or no.
set -e

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

die() {
    echo >&2 "$@"
    exit 1
}

usage() {
    local script_name=$(basename "${0}")
    echo "usage: ${script_name} [--version {7.9p1,8.0p1,8.1p1,8.2p1,8.3p1}] [--output_rpm_dir PATH] [--upgrade_now yes|no]"
}

build_RPMs() {
    local output_rpm_dir="${1}"
    yum install -y pam-devel rpm-build rpmdevtools zlib-devel openssl-devel krb5-devel gcc wget libx11-dev gtk2-devel libXt-devel imake ca-certificates
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
    sed -i -e "/check-files/ s/^#*/#/" /usr/lib/rpm/macros

    rpmbuild -ba openssh.spec
    cd /root/rpmbuild/RPMS/x86_64/
    tar zcvf ${output_rpm_dir}/openssh-${version}-RPMs.el${rhel_version}.tar.gz openssh*
    rm -rf ~/rpmbuild ~/openssh-${version}
}

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
    sed -i '/PermitRootLogin yes/ s/^#*//' /etc/ssh/sshd_config
    chmod 600 /etc/ssh/ssh*
    /etc/init.d/sshd restart
    echo "New version upgrades as to lastest:"
    $(ssh -V)
}

main() {
    # Parse arguments
    local version="8.3p1"
    local output_rpm_dir=""
    local upgrade_now=""
    local install_only=""
    rhel_version=$(rpm -q --queryformat '%{VERSION}' centos-release)

    while [[ "$#" -gt 0 ]]; do
        opt="$1"
        case "${opt}" in
        --version)
            version="$2"
            shift
            shift || break
            ;;
        --output_rpm_dir)
            output_rpm_dir="$2"
            shift
            shift || break
            ;;
        --upgrade_now)
            upgrade_now="$2"
            echo "You set upgrade now is ${upgrade_now}"
            shift
            shift || break
            ;;
        --install_only)
            install_only="$2"
            shift
            shift || break
            ;;
        *)
            usage
            exit 1
            ;;
        esac
    done

    if [[ -z ${version} ]]; then
        usage
        exit 1
    fi

    if [[ ! -z ${output_rpm_dir} ]] && [[ ! -d "${output_rpm_dir}" ]]; then
        mkdir -p ${output_rpm_dir}
    fi

    local temp_dir="$(mktemp -d)"
    trap "rm -rf ${temp_dir}" EXIT
    pushd "${temp_dir}"

    output_dir=${output_rpm_dir:-${temp_dir}}

    if [[ ! -z ${install_only} ]] && [[ ! -z ${output_rpm_dir} ]]; then
        upgrade_openssh "${output_dir}"
        exit
    fi

    echo "Start build openssh-${version}-RPMs ..."
    sleep 1s
    build_RPMs "${output_dir}"
    if [[ -z ${upgrade_now} ]]; then
        while true; do
            read -p "You don't set upgrade_now value, do you want install upgrade now? [y/N]: " yn
            case $yn in
            [Yy]*)
                upgrade_openssh "${output_dir}"
                break
                ;;
            [Nn]*)
                if [[ ${output_dir} != ${output_rpm_dir} ]]; then
                    echo "Build success without upgrade"
                else
                    echo "The rpm files was put in ${output_rpm_dir}. check it out."
                fi
                exit
                ;;
            *) echo "Please answer yes or no." ;;
            esac
        done
        exit
    fi

    case ${upgrade_now} in
    [Yy]*)
        echo "You choose upgrade OpenSSH now, start upgrade OpenSSH using rpm -U ..."
        sleep 1s
        upgrade_openssh "${output_dir}"
        exit
        ;;
    *)
        if [[ ${output_dir} != ${output_rpm_dir} ]]; then
            echo "Build success without upgrade"
        else
            echo "The rpm files was put in ${output_rpm_dir}. check it out."
        fi
        exit
        ;;
    esac

}

main "$@"
