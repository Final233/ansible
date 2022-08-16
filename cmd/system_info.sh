#!/usr/bin/env bash
#
#********************************************************************
#Author:                Final
#Date:                  2022-08-12
#FileName：             system_info.sh
#Description：          This is bash script
#Copyright (C):         2022 All rights reserved
#********************************************************************

_separator() {
    echo "--------------------------------------------------------------------"
}

TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
_printf() {
    case "$1" in
    info)
        echo -e "\033[36m$2\033[0m ${@:3}"
        ;;

    *) ;;
    esac
}

# CPU型号
cpu_model=$(awk -F': ' '/model name/{print $NF}' /proc/cpuinfo | uniq)
# 逻辑核心数，若有超线程，物理核心数*2=逻辑核心数  lscpu | grep ^CPU\(s\)
cpu_core_num=$(grep -c "model name" /proc/cpuinfo)
# 用户空间
cpu_user=$(top -b -n 1 | tr ',' ' ' | awk '/Cpu/{print $2"%"}')
# 内核空间
cpu_system=$(top -b -n 1 | tr ',' ' ' | awk '/Cpu/{print $4"%"}')
# 空闲空间
cpu_idle=$(top -b -n 1 | tr ',' ' ' | awk '/Cpu/{print $8"%"}')
# 输入输出占用CPU百分比
cpu_iowait=$(top -b -n 1 | tr ',' ' ' | awk '/Cpu/{print $10"%"}')
# CPU中断次数
# 什么是中断，当一个员工正在工作时，突然手机响了（中断请求），不得不在文件上做一个记号（返回地址），暂停工作，去接电话（中断），并按照某某方案办（调用中断服务程序），然后静下心来（恢复中断前状态），接着处理
# 从概念上讲：中断是cpu处理外部突发事件的一个重要技术。它能使cpu在运行过程中对外部事件发出的中断请求及时地进行处理，处理完成后又立即返回断点，继续进行cpu原来的工作。也就说是中断发生时cpu依然在工作,只是处理了中断请求而已
# 中断有分硬中断和软中断，简单来说硬/软件发送中断请求
# 对于硬中断来说，所有的设备都链接着一个叫做Interrupt Request(IRQ) Line的东西，这个东西链链接硬件和cpu
# 硬中断的过程
# 1、硬件发起IRQ，中断控制器收到IRQ会将相应的信号发送给cpu
# 2、cpu收到IRQ后中断当前运行的程序
# 3、硬件收到消息，刚刚发送的IRQ被cpu收到
# 4、request action(ISR)开始运行
# 5、结束后中断的程序继续执行
# 软中断顾名思义是软件发起的中断
# 软中断是当前运行的程序用于请求I/O,因为我们知道在中断处理时CPU没法处理其它事物，对于网卡来说，如果每次网卡收包时中断的时间都过长，那很可能造成丢包的可能性，对于某些io请求也许会完成的非常快，但是对于磁盘io来说经常先被放入队列，然后在稍后的事件完成
# 硬中断是直接对cpu说，软中断是只对内核说
# 网络io先发起硬中断通知cpu将数据从网卡的缓存中copy到内存中（只是copy其他复杂操作给软中断做），然后触发软中断，由内核去解析内存中的数据包，硬中断要做到快，因为cpu接受到中断会暂停执行当前的程序，如果硬中断慢，那么说明cpu要被挂起相当一段时间
cpu_interrupt=$(vmstat -n 1 1 | sed -n 3p | awk '{print $11}')
# 现在linux是大多基于抢占式，CPU给每个任务一定的服务时间，当时间片轮转的时候，需要把当前状态保存下来，同时加载下一个任务，这个过程叫做上下文切换。时间片轮转的方式，使得多个任务利用一个CPU执行成为可能，但是保存现场和加载现场，也带来了性能消耗
# ​context switch过高，会导致CPU像个搬运工，频繁在寄存器和运行队列直接奔波，更多的时间花在了线程切换，而不是真正工作的线程上。直接的消耗包括CPU寄存器需要保存和加载，系统调度器的代码需要执行。间接消耗在于多核cache之间的共享数据
cpu_context_switch=`vmstat -n 1 1 | sed -n 3p | awk '{print $12}'`
# CPU负载1分钟前
cpu_load_1min=$(uptime | tr -d , | awk '{print $(NF-2)}')
# CPU负载5分钟前
cpu_load_5min=$(uptime | tr -d , | awk '{print $(NF-1)}')
# CPU负载15分钟前
cpu_load_15min=$(uptime | tr -d , | awk '{print $(NF)}')
# 可运行进程的数量(正在运行或等待运行时)
cpu_task_length=$(vmstat -n 1 1 | sed -n 3p | awk '{print $1}')

# 物理内存总量
mem_total=$(free -h | awk '/Mem/{print $2}')
# 已使用内存总量
mem_sys_used=$(free -h | awk '/Mem/{print $3}')
# 剩余内存总量
mem_use_free=$(free -h | awk '/Mem/{print $4}')
# 交换分区总量
mem_swap_total=$(free -h | awk '/Swap/{print $2}')
# 已使用交换分区问题
mem_swap_used=$(free -h | awk '/Swap/{print $3}')
# 剩余交换分区大小
mem_swap_free=$(free -h | awk '/Swap/{print $4}')

# 磁盘IO统计
# 每秒向设备发起读请求数
disk_sda_rs=$(iostat -kx | awk '/sda/{print $4}')
# 每秒向设备发起写请求数
disk_sda_ws=$(iostat -kx | awk '/sda/{print $5}')
# 发送到设备的请求的平均队列长度，IO请求队列平均长度
disk_sda_avgqu_sz=$(iostat -kx | awk '/sda/{print $9}')
# 发送给设备的I/O请求的平均时间(以毫秒为单位)。这包括花费的时间队列中的请求和服务它们所花费的时间
disk_sda_await=$(iostat -kx | awk '/sda/{print $10"ms"}')
# 向设备发出I/O请求的运行时间百分比(设备的带宽利用率)。当这个值接近100%时，设备就会饱和
disk_sda_util=$(iostat -kx | awk '/sda/{print $NF}')

# 系统运行时间统计
system_run_time=$(awk -F. '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("系统已运行：%d天%d时%d分%d秒",run_days,run_hour,run_minute,run_second)}' /proc/uptime)
# 内核版本
kernel_version=$(uname -r)
# 硬件平台架构
hardware_platform=$(uname -i)
# 操作系统名称
os_name=$(sed -rn 's/PRETTY_NAME="(.*)"/\1/p' /etc/os-release)
# 连接状态统计
# connect_status=$(ss -s)
# 本机IP列表
local_ip=$(ip a | tr / ' ' | awk '/inet /{print $2}' | grep -v 127.0.0.1)

_separator
_printf info time: $TIMESTAMP
_printf info "系统已运行:" $system_run_time
_printf info "操作系统:" $os_name
_printf info "内核版本:" $kernel_version
_printf info "硬件架构:" $hardware_platform
_printf info local_ip: $local_ip
_printf info "打印硬盘超过80%的分区"
df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
_separator
_printf info "cpu model name:" $cpu_model
_printf info "cpu core num:" $cpu_core_num
_printf info "cpu user space:" $cpu_user
_printf info "cpu system space:" $cpu_system
_printf info "cpu free:" $cpu_idle
_printf info "cpu io:" $cpu_iowait
_printf info "cpu interrupt:" $cpu_interrupt
_printf info "cpu context switch:" $cpu_context_switch
_printf info "cpu process running or waitting rum time:" $cpu_task_length
_separator
_printf info "mem total:" $mem_total
_printf info "mem sys used:" $mem_sys_used
_printf info "mem free space:" $mem_use_free
_printf info "mem swap total:" $mem_swap_total
_printf info "mem swap used:" $mem_swap_used
_printf info "mem swap free space:" $mem_swap_free
_separator
_printf info "每秒向设备发起读请求数:" $disk_sda_rs
_printf info "每秒向设备发起写请求数:" $disk_sda_ws
_printf info "IO请求队列平均长度:" $disk_sda_avgqu_sz
_printf info "发送给设备的I/O请求的平均时间:" $disk_sda_await
_printf info "向设备发出I/O请求的运行时间百分比(设备的带宽利用率):" $disk_sda_util
_separator
_printf info "connect status" 
ss -s
_separator
_printf info "network io list" 
sar -n DEV 1 1
