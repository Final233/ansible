#!/usr/bin/env bash
#
#Author:                Final
#Date:                  2020-05-21
#Copyright (C):         2020 All rights reserved
#--------------------------------------------------------------------

DATE=$(date +%F-%T)
rm -f bak-*.tar.gz
# git remote set-url origin https://xxxxxxx.com/cangku
git rm -r --cached
git add -A
git commit -m "$DATE"
git push && echo 上传成功
#DATE=$(date +%Y%m%d)
#tar zcf bak-${DATE}.tar.gz * && echo 备份完成
