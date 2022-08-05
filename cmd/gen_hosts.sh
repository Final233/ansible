#!/usr/bin/env bash
# 读取文件生成hosts文件
echo [tdgw] > ../hosts
#/tmp/192.168.10.88/home/tdgw/scripts/run.sh
file_name=$(find /tmp/ -type f -name info)
for i in $file_name; do
    ip=$(echo $i | awk -F/ '{print $3}') #192.168.10.88
    vars=$(cat $i | sed 's/^/PBU/' | sed ':a;N;$!ba;s/\n/ /g')
    echo $ip $vars >> ../hosts
done

