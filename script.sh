#!/bin/bash

# example is taken from https://github.com/nixuser/zfs/blob/master/setup_zfs.sh
yum install -y yum-utils

# https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html
yum install -y https://zfsonlinux.org/epel/zfs-release-2-2$(rpm --eval "%{dist}").noarch.rpm
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs
modprobe zfs
yum install -y wget