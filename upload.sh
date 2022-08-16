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
rm -f ../logs/*.log ../files/*

# git rm -r --cached
git add -A
git commit -m "$DATE"
git push && echo 上传成功
git gc

