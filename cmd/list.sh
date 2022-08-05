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
    cd $(dirname $0)
    pwd
)

cd $basepath

bash /home/tdgw/scripts/mod_time.sh list