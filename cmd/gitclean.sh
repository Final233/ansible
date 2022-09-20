#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2020-05-21
#Copyright (C):         2020 All rights reserved
#********************************************************************

basepath=$(
    cd $(dirname $0)
    pwd
)

cd $basepath/../
DATE=$(date +%F-%T)
git count-objects -vH   # 此时还是旧的大小
git gc --prune=now  # 清理无效文件
git count-objects -vH  # 此时就和本地一样,从库减小了
