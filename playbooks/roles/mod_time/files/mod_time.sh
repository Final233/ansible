#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#FileName：             mod_time.sh
#Copyright (C):         2022 All rights reserved
#********************************************************************

#find /home/tdgw -name 'MTP-Pbu.json' | xargs grep knockDoorInAdvanceMs
#find /home/tdgw/ -name 'MTP-Pbu.json' | xargs grep pbu
#find /home/tdgw/AUTOF* -name 'MTP-Pbu.json'
#sed -rn '/knockDoorInAdvanceMs/s@(.* ).*,@\188,@p'  MTP-Pbu.json
#grep 'pbu"' MTP-Pbu.json | tr -d '":,' | awk '{print $NF}'
basepath=$(
    cd $(dirname $0)
    pwd
)

cd $basepath

_vars() {
    DATE=$(date +%Y%m%d)
    DATE1=$(date +%Y%m%d-%H%M%S)
    NIC=""
    # NIC="${@: -1}"
    NIC="$2"
    if [ "$NIC" == "ens33" ]; then
        NIC="ens33"
    elif [ "$NIC" == "bond0" ]; then
        NIC="bond0"
    elif [ "$NIC" == "team0" ]; then
        NIC="team0"
    elif [ "$NIC" == "eth1" ]; then
        NIC="eth1"
    else
        NIC="eth0"
    fi
    local_ip=$(/usr/sbin/ip address show $NIC | awk -F/ '/inet /{print $1}' | awk '{print $2}')
    file_name='MTP-Pbu.json'
}

_list() {
    file_path=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
    for i in $file_path; do
        pbu=$(grep 'pbu"' $i | tr -d '":,' | awk '{print $NF}')
        time=$(awk '/knockDoorInAdvanceMs/{print $NF}' $i | tr -d ,)
        echo $i $pbu $time
    done
}

_file() {
    echo "#!/usr/bin/env bash" >run.sh
    file_path=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
    for i in $file_path; do
        pbu=$(grep 'pbu"' $i | tr -d '":,' | awk '{print $NF}')
        time=$(awk '/knockDoorInAdvanceMs/{print $NF}' $i | tr -d ,)
        echo bash $0 mod $pbu $time >>run.sh
    done
    # echo bash $0 list >>run.sh
    chmod a+x run.sh
}

_hosts() {
    file='hosts'
    if [ -f hosts ]; then
        ip_list=$(sed -rn '/PBU/s/^([0-9.]+)(.*)/\1/p' $file)
        bash_filename="run.sh"
        echo "#!/usr/bin/env bash" >$bash_filename
        for ip in $ip_list; do
            if [ "$local_ip" == "$ip" ]; then
                # 取pbu及时间的值
                value=$(sed -rn "/$ip /s/^([0-9.]+)(.*)/\2/p" $file | sed 's/^ //')
                echo "# $ip" >>$bash_filename
                for j in $value; do
                    pbu_time=$(echo $j | sed 's/=/ /;s/PBU//')
                    echo "bash $basepath/mod_time.sh mod $pbu_time" >>$bash_filename
                done
            fi
        done
        chmod a+x $bash_filename
    else
        echo "hosts file not exist"
    fi
}

_mod() {
    if [ $# -ge 3 ]; then
        file_list=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
        time=$3
        for file_path in $file_list; do
            run_path=${file_path/cfg\/${file_name}/}
            pbu=$(grep 'pbu"' $file_path | tr -d '":,' | awk '{print $NF}')
            if [ "$2" -eq "$pbu" ]; then
                [ -d $basepath/backup/${DATE} ] || mkdir -p $basepath/backup/${DATE}
                cp -a $file_path $basepath/backup/${DATE}/${file_name}_bak_${DATE1}_${pbu}${file_path////_}
                # cd $run_path && bash shutdown.sh
                sed -ri "/knockDoorInAdvanceMs/s@(.* ).*,@\1"${time:=100}",@" $file_path && echo "$pbu mod_time is succ"
                # cd $run_path && bash startup.sh
            fi
        done
    else
        _usage
    fi
}

_usage() {
    echo -e "
注：脚本请放入 /home/tdgw/scripts 目录下执行
Usage: bash command [options] [args] 

Samples:
    bash $0 list # 查看
    bash $0 file # 生成 run.sh
    bash $0 hosts
    bash $0 mod 12345 88 # PBU [NUM(1-100)]
==============================================================================
\n"
}

_cmd() {
    case $1 in
    mod)
        _mod "$@"
        ;;
    list)
        _list
        ;;
    file)
        _file
        ;;
    hosts)
        _hosts "$@"
        ;;
    *)
        _usage
        ;;
    esac
}

_vars "$@"
_cmd "$@"
