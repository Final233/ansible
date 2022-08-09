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
    cd $(dirname $0)./
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
         $0 setup 06 --skip-tags del_mod_time_back
         $0 limit 06 192.168.10.88 (对hosts中单个IP进行执行)

         $0 setup 07 (or $0 setup rysnc_file)
         $0 setup 07 /mnt/d/box/ansible /tmp (default cp -rf /mnt/d/box/ansible /tmp/)
         $0 setup 07 /tmp/file /data (cp -f /tmp/file /data/file) ---- rsync file
         $0 setup 07 /tmp/dir/ /data (cp -rf /tmp/dir/* /data/dir/.) ---- rsync file
         $0 setup 07 /tmp/dir /data (cp -rf /tmp/dir /data/dir) ---- rsync dir

         $0 setup all
         $0 setup 01 -vvv (or -v or -vv 显示详细信息)
         $0 setup 01 -C (测试运行)
EOF
}

_vars() {
    date=$(date +%Y%m%d)
    src_file=""
    dest_file=""
    tags=""
    if [ $# -ge 2 ]; then
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
    fi
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
        if [ $PLAY_BOOK == "07.rsync_file.yml" ]; then
            src_file="-e src_file="$3""
            dest_file="-e dest_file="$4""
        fi
        if [ "$3" == "--skip-tags" ]; then
            tags="--skip-tags $4"
        fi
        log_path="logs/${PLAY_BOOK/.yml/}-$date.log"
        echo $log_path
        cmd="ansible-playbook -i inventory/hosts -e @config.yml $src_file $dest_file $tags playbooks/$PLAY_BOOK $DEBUG"
        unbuffer $cmd | tee -a $log_path
        # $cmd >> ../logs/"$PLAY_BOOK"_"$date".log && tail ../logs/"$PLAY_BOOK"_"$date".log
        # echo $cmd
        ;;
    limit)
        _setup "$@"
        log_path="logs/${PLAY_BOOK/.yml/}-$date.log"
        host=$3
        if [ $# -ge 5 ]; then
            src_file="-e src_file="$4""
            dest_file="-e dest_file="$5""
        fi
        if [ "$4" == "--skip-tags" ]; then
            tags="--skip-tags $5"
        fi
        _setup "$@"
        cmd="ansible-playbook -i inventory/hosts -e @config.yml  $src_file $dest_file playbooks/$PLAY_BOOK $tags --limit $host $DEBUG"
        unbuffer $cmd | tee -a $log_path
        # $cmd >> ../logs/"$PLAY_BOOK"_"$date".log
        ;;
    ping)
        cmd="ansible-playbook -i inventory/hosts -e @config.yml playbooks/${PLAY_BOOK:=00.ping.yml}"
        $cmd
        ;;
    test)
        cmd="ansible-playbook -i inventory/hosts -e @config.yml playbooks/${PLAY_BOOK:=98.test.yml} $DEBUG"
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

_vars
_cmd "$@"
