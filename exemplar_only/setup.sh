#!/bin/bash
apt-get clean
apt-get update

#Add test envrionment packages
apt-get -y install software-properties-common
add-apt-repository -y ppa:arighi/virtme-ng
DEBIAN_FRONTEND=noninteractive apt-get install -y busybox-static python3 virtme-ng libvirt-daemon-system wget bc binutils bison build-essential dwarves flex gcc git gnupg2 gzip libelf-dev libncurses5-dev libssl-dev make openssl pahole perl-base rsync tar xz-utils
DEBIAN_FRONTEND=noninteractive apt-get remove -y software-properties-common
