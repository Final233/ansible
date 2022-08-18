#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2022-08-18
#FileName：             new.sh
#Description：          The test script
#Copyright (C):         2022 All rights reserved
#********************************************************************

basepath=$(
    cd $(dirname $0)
    pwd
)
cd $basepath
cd ../playbooks/roles
if [ -z $1 ]; then
    echo $0 dirname
else
    cp -a demo $1
fi
