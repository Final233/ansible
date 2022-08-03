#!/usr/bin/env bash

timedatectl set-timezone Asia/Shanghai
systemctl set-default multi-user.target
ulimit -c unlimited
virsh net-destroy default &>/dev/null
virsh net-undefine default &>/dev/null
sed '/SELINUX=/s/enforcing/disabled/' /etc/selinux/config -i
# tuned-adm profile network-latency
# x86_energy_perf_policy performance