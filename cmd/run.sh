#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#QQ:                    438803792
#Date:                  2022-08-03
#FileName：             test.sh
#URL:                   http://cnblogs.com/fina
#Description：          The test script
#Copyright (C):         2022 All rights reserved
#********************************************************************

basepath=$(
    cd $(dirname $0)
    pwd
)

cd $basepath/
cd ../playbooks

# ansible-playbook 01.prepare.yml
# ansible-playbook -i ../hosts mod_time_role.yml --limit 192.168.10.89

_usage() {
    echo -e "\033[33mUsage:\033[0m $0 setup <num> <playbook>"
    cat <<EOF
available steps:
    01  prepare            to prepare system settings 
    02  nginx              to setup nginx source
    03  httpd              to setup httpd
    04  httpd_nginx        to setup httpd and nginx
    99  all                to run 01~07 all at once

examples: $0 setup 01 (or $0 setup prepare)
	 $0 setup 02 (or $0 setup nginx)
         $0 setup all
EOF
}

_setup() {
    case "$2" in
    01 | prepare)
        PLAY_BOOK="01.prepare.yml"
        ;;
    02 | nginx)
        PLAY_BOOK="02.etcd.yml"
        ;;
    03 | httpd)
        PLAY_BOOK="03.runtime.yml"
        ;;
    04 | httpd_nginx)
        PLAY_BOOK="04.kube-master.yml"
        ;;
    99 | all)
        PLAY_BOOK="90.setup.yml"
        ;;
    *)
        _usage
        exit 1
        ;;
    esac
}

_setup
