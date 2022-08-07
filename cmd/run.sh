#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2022-08-03
#FileName：             run.sh
#Description：          This is bash script
#Copyright (C):         2022 All rights reserved
#********************************************************************

basepath=$(
    cd $(dirname $0)
    pwd
)

cd $basepath

_usage() {
    echo -e "\033[33mUsage:\033[0m $0 setup <num> <playbook>"
    cat <<EOF
available steps:
    00  ping               to ping status
    01  prepare            to prepare system settings 
    02  nginx              to setup nginx source
    03  httpd              to setup httpd
    04  httpd_nginx        to setup httpd and nginx
    05  memcached          to setup memcached
    06  mod_time           to setup mod_time
    07  rysnc_file         to setup rsync_file
    99  all                to run 01~99 all at once

examples: $0 setup 01 (or $0 setup prepare)
	 $0 setup 02 (or $0 setup nginx)
         $0 limit 06 192.168.10.88 (对hosts中单个IP进行执行)
         $0 setup all
         $0 setup 01 -vvv (or -v or -vv 显示详细信息)
         $0 setup 01 -C (测试运行)
EOF
}

_setup() {
    case "$2" in
    00 | ping)
        PLAY_BOOK="00.ping.yml"
        ;;
    01 | prepare)
        PLAY_BOOK="01.prepare.yml"
        ;;
    02 | nginx)
        PLAY_BOOK="02.nginx.yml"
        ;;
    03 | httpd)
        PLAY_BOOK="03.httpd.yml"
        ;;
    04 | httpd_nginx)
        PLAY_BOOK="04.httpd_nginx.yml"
        ;;
    05 | memcached)
        PLAY_BOOK="05.memcached.yml"
        ;;
    06 | mod_time)
        PLAY_BOOK="06.mod_time.yml"
        ;;
    07 | rsync_file)
        PLAY_BOOK="07.rsync_file.yml"
        ;;
    99 | all)
        PLAY_BOOK="99.setup.yml"
        ;;
    *)
        _usage
        exit 1
        ;;
    esac
}

_cmd() {
    case $1 in
    setup)
        _setup "$@"
        # echo $PLAY_BOOK
        cmd="ansible-playbook -i ../hosts -e @../config.yml ../playbooks/$PLAY_BOOK $DEBUG"
        $cmd
        ;;
    limit)
        _setup "$@"
        cmd="ansible-playbook -i ../hosts -e @../config.yml ../playbooks/$PLAY_BOOK --limit $3 $DEBUG"
        $cmd
        ;;
    ping)
        cmd="ansible-playbook -i ../hosts -e @../config.yml ../playbooks/${PLAY_BOOK:=00.ping.yml}"
        $cmd
        ;;
    test)
        cmd="ansible-playbook -i ../hosts -e @../config.yml ../playbooks/${PLAY_BOOK:=98.test.yml} $DEBUG"
        $cmd
        ;;

    *)
        _usage
        ;;
    esac
}

DEBUG="${@: -1}"
if [ $DEBUG == "-vvv" ]; then
    DEBUG="-vvv"
elif [ $DEBUG == "-vv" ]; then
    DEBUG="-vv"
elif [ $DEBUG == "-v" ]; then
    DEBUG="-v"
elif [ $DEBUG == "-C" ]; then
    DEBUG="-C"
elif [ $DEBUG == "-Cv" ]; then
    DEBUG="-C -v"
elif [ $DEBUG == "-Cvv" ]; then
    DEBUG="-C -vv"
elif [ $DEBUG == "-Cvvv" ]; then
    DEBUG="-C -vvv"
else
    DEBUG=""
fi

_cmd "$@"
