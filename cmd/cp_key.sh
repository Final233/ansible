#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2022-08-07
#FileName：             cp_key.sh
#Description：          This is bash script
#Copyright (C):         2022 All rights reserved
#********************************************************************

_key_gen(){
    ssh_key_file=~/.ssh/id_rsa.pub
    [ -f $ssh_key_file ] ||( ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && echo "ssh key gen is succ")
}

_copy_key(){
    ip=$1
    user=$2
    password=$3
expect <<EOF
set timeout 20
spawn ssh-copy-id -o StrictHostKeyChecking=no $user@$ip
expect {
    "password" { send "$password\\n" }
}
expect eof
EOF
}

_usage() {
    echo -e "\033[33mUsage:\033[0m $0 < ip > < username > < password > \n"
    cat <<EOF
examples: $0 root password 127.0.0.1
EOF
}

_pkg_check(){
    if which expect &> /dev/null;then
        pkg_check="expect"
    elif which sshpass &> /dev/null;then
        pkg_check="sshpass"
    else
        echo "pelase insttall expect or sshpass" && exit 2
    fi
}

_pkg_check
if [ $# -ge 3 ]; then
    _key_gen
    if [ $pkg_check == "expect" ];then
        _copy_key "$@"
    elif [ $pkg_check == "sshpass" ];then
        ip=$1
        user=$2
        password=$3
        sshpass -p $password ssh-copy-id  -o StrictHostKeyChecking=no $user@$ip
    else
        echo "pelase insttall expect or sshpass" && exit 2
    fi
else
    _usage
fi