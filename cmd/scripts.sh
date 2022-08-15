#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2022-08-07
#FileName：             scripts.sh
#Description：          This is bash script
#Copyright (C):         2022 All rights reserved
#********************************************************************

basepath=$(
    cd $(dirname $0)
    pwd
)

cd $basepath

echo script_name store $basepath
echo ./run scripts scripts.sh