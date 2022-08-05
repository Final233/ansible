#!/usr/bin/env bash

egrep -v '.*:*|:!' /etc/shadow | awk -F: '{print $1}'
if [ $? -le 0 ]; then
    echo 未检查出未使用的账号
else
    echo "锁定账号 /usr/sbin/usermod -L -s /dev/null USERNAME"
    echo "删除账号 /usr/sbin/userdel USERNAME"
fi

#禁止空密码登录
grep -q "^#PermitEmptyPasswords no" /etc/ssh/sshd_config && sed -i '/^#PermitEmptyPasswords no/s/#//g' /etc/ssh/sshd_config 

# grep -q remember=5 /etc/pam.d/system-auth || ( cp /etc/pam.d/system-auth{,bak_$DATE} && sed -ri '/password    sufficient/s/(.*)/\1 remember=5/g' /etc/pam.d/system-auth )
echo -e "列出空口令用户:"
awk -F: '($2 == "") { print $1 }' /etc/shadow

#密码长度不小于 8 个字符，至少包含大小写字母、数字及特殊符号中的 3 类
# grep -q minlen=8 /etc/pam.d/system-auth || sed -ri '/password    requisite/s/(.*)/\1 minlen=8 minclass=3/g' /etc/pam.d/system-auth

echo "列出UID为0的用户:" && awk -F ':' '($3 == "0"){print $1}' /etc/passwd

echo "列出重要的文件及目录权限标准:"
ls -l /etc/passwd /etc/group /etc/shadow
#chmod 644 /etc/passwd /etc/group && chmod 000 /etc/shadow
#chmod 000 /etc/shadow || chmod 400 /etc/shadow

#禁用 ctrl-alt-delete
[ -f /usr/lib/systemd/system/ctrl-alt-del.target ] && ( rm -f /usr/lib/systemd/system/reboot.target && init q )

#设置最小密码长度
#cp -p /etc/login.defs /etc/login.defs.bak
#sed  -i '/^PASS_MIN_LEN/s/5/12/g' /etc/login.defs

#设置密码复杂度
#cp -p /etc/pam.d/system-auth-ac /etc/pam.d/system-auth-ac.bak
#sed -i 's/.* pam_pwquality.so.*/password    requisite     pam_cracklib.so try_first_pass retry=10 minlen=12 minclass=3 lcredit=-1 ucredit=-1 dcredit=-1 ocredit=-1 type='/g /etc/pam.d/system-auth-ac

#cp -p /etc/pam.d/password-auth-ac /etc/pam.d/password-auth-ac.bak
#sed -i 's/.* pam_pwquality.so.*/password    requisite     pam_cracklib.so try_first_pass retry=10 minlen=12 minclass=3 lcredit=-1 ucredit=-1 dcredit=-1 ocredit=-1 type='/g /etc/pam.d/password-auth-ac

#登录失败10次锁定
#sed -i '4 a\auth        required      pam_tally2.so onerr=fail deny=10 unlock_time=300' /etc/pam.d/system-auth-ac
#sed -i '4 a\auth        required      pam_tally2.so onerr=fail deny=10 unlock_time=300' /etc/pam.d/password-auth-ac

#禁止root远程登录
#sed -i '/^#PermitRootLogin/cPermitRootLogin no' /etc/ssh/sshd_config

#删除潜在威胁文件
find / -maxdepth 3 -name hosts.equiv -o -name .netrc -o -name .rhosts

# sshd -t && systemctl restart sshd