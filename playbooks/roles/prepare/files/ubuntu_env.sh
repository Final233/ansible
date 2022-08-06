# setterm -blank 0
TMOUT=900
export EDITOR=vim
HISTTIMEFORMAT="%F %T $(whoami) $(who -u am i | awk '{print $(NF)}' | sed -e 's/[()]//g') "
umask 027
PS1="\[\e[1;36m\][\u@\h \W]\\$ \[\e[0m\]"