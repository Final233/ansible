#!/usr/bin/env bash
# 读取hosts文件转换成执行脚本文件run.sh
basepath=$(
  cd $(dirname $0)
  pwd
)
cd $basepath

file='hosts'
if [ -f hosts ]; then
  ip=$(sed -rn '/PBU/s/^([0-9.]+)(.*)/\1/p' $file)
  bash_filename="run.sh"
  echo "#!/usr/bin/env bash" >$bash_filename
  for i in $ip; do
    vars=$(sed -rn "/$i/s/^([0-9.]+)(.*)/\2/p" $file | sed 's/^ //')
    echo "# $i" >>$bash_filename
    for j in $vars; do
      var=$(echo $j | sed 's/=/ /;s/PBU//')
      echo "bash $basepath/mod_time.sh $var" >>$bash_filename
    done
  done
else
  echo "hosts 文件不存在"
fi
