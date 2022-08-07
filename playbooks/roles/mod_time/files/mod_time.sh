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
DATE=$(date +%Y%m%d)
DATE1=$(date +%Y%m%d-%H%M%S)
NIC='eth0'
ip=$(/usr/sbin/ip address show $NIC | awk -F/ '/inet/{print $1}' | awk '{print $2}')
_run() {
    file_name='MTP-Pbu.json'
    if [ $# -ge 2 ]; then
        file_list=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
        time=$2
        for file_path in $file_list; do
            run_path=${file_path/cfg\/${file_name}/}
            pbu=$(grep 'pbu"' $file_path | tr -d '":,' | awk '{print $NF}')
            if [ "$1" -eq "$pbu" ]; then
                [ -d $basepath/backup/${DATE} ] || mkdir -p $basepath/backup/${DATE}
                cp -a $file_path $basepath/backup/${DATE}/${file_name}_bak_${DATE1}_${pbu}${file_path////_}
                # cd $run_path && bash shutdown.sh
                sed -ri "/knockDoorInAdvanceMs/s@(.* ).*,@\1"${time:=100}",@" $file_path && echo "$pbu mod_time is succ"
                # cd $run_path && bash startup.sh
            fi
        done
    elif [ "$1" == "list" ]; then
        # file_list=$(find /home/tdgw/AUTOF* -type f -name ${file_name} | xargs grep 'pbu"' | tr -d '":,' | awk '{print $1,$NF}')
        # file_time=$(find /home/tdgw/AUTOF* -type f -name ${file_name} | xargs grep 'knockDoorInAdvanceMs' | awk '{print $1,$NF}' | tr -d ,)
        file_path=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
        for i in $file_path; do
            pbu=$(grep 'pbu"' $i | tr -d '":,' | awk '{print $NF}')
            time=$(awk '/knockDoorInAdvanceMs/{print $NF}' $i | tr -d ,)
            echo $i $pbu $time
        done
    elif [ "$1" == "file" ]; then
        # > info
        # echo $ip >> info
        echo "#!/usr/bin/env bash" > run.sh
        file_path=$(find /home/tdgw/AUTOF* -type f -name ${file_name})
        for i in $file_path; do
            pbu=$(grep 'pbu"' $i | tr -d '":,' | awk '{print $NF}')
            time=$(awk '/knockDoorInAdvanceMs/{print $NF}' $i | tr -d ,)
            echo bash $0 $pbu $time >> run.sh
            # echo "$pbu=$time" >> info
        done
        # echo bash $0 list >>run.sh
        chmod a+x run.sh
    else

        echo -e "
注：脚本请放入 /home/tdgw/scripts 目录下执行
Usage: bash command [options] [args] 

Samples:
    bash $0 list # 查看
    bash $0 file # 生成 run.sh
    bash $0 12345 88 # PBU [NUM(1-100)]
==============================================================================
\n"
    fi
}

_run "$@"
