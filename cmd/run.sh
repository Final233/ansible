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
for i in $(ls -1 | grep -v roles ); do
    echo $0 $i
done

# ansible-playbook 01.prepare.yml
