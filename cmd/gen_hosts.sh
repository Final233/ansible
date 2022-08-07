#!/usr/bin/env bash
# 读取文件生成hosts文件

#/tmp/192.168.10.88/home/tdgw/scripts/run.sh
file_name=$(find /tmp/ -type f -name run.sh)
echo "[tdgw]" > ../hosts
for i in $file_name; do
    ip=$(echo $i | awk -F/ '{print $3}') #192.168.10.88
    # vars=$(cat $i | sed 's/^/PBU/' | sed ':a;N;$!ba;s/\n/ /g')
    vars=$(awk '/mod_time/{print "PBU"$(NF-1)"="$NF}' $i | sed ':a;N;$!ba;s/\n/ /g')
    echo $ip $vars >> ../hosts
done

