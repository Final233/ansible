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

_logger() {
    TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
    case "$1" in
    debug)
        echo -e "$TIMESTAMP \033[36mDEBUG\033[0m ${@:2}"
        ;;
    info)
        echo -e "$TIMESTAMP \033[32mINFO\033[0m ${@:2}"
        ;;
    warn)
        echo -e "$TIMESTAMP \033[33mWARN\033[0m ${@:2}"
        ;;
    error)
        echo -e "$TIMESTAMP \033[31mERROR\033[0m ${@:2}"
        ;;
    *) ;;

    esac
}

_log() {
    case "$1" in
    off)
        true
        ;;
    *)
        log_path="logs/${PLAY_BOOK/.yml/}-$date.log"
        export ANSIBLE_LOG_PATH="$basepath/$log_path"
        ;;
    esac
}

_usage(){
    echo -e "\033[33mUsage:\033[0m $0 [args]"
cat <<EOF
available steps:
    $0 setup [01-99]
    $0 ping
    $0 test
    $0 rsync SOURCE_FILE DEST_FILE
    $0 scripts system_info.sh (or $0 scripts scripts.sh)
    $0 addmaster IP
    $0 delmaster IP
    $0 addnode IP
    $0 delnode IP

examples:
        $0 limit 06 192.168.10.88 (对hosts中单个IP进行执行)

        $0 rsync /mnt/d/box/ansible /tmp/ (default cp -rf /mnt/d/box/ansible /tmp/)
        $0 rsync /tmp/file /data/ (cp -f /tmp/file /data/file) ---- rsync file
        $0 rsync /tmp/dir/ /data/ (cp -rf /tmp/dir/* /data/dir/.) ---- rsync file
        $0 rsync /tmp/dir /data/ (cp -rf /tmp/dir /data/dir) ---- rsync dir

        $0 setup 01 -vvv (or -v or -vv 显示详细信息)
        $0 setup 01 -C (测试运行)
EOF
}

_usage_setup() {
    echo -e "\033[33mUsage:\033[0m $0 setup <num> <playbook>"
    cat <<EOF
available steps:
    01  prepare            to prepare system settings 
    02  nginx              to setup nginx source
    03  httpd              to setup httpd
    04  httpd_nginx        to setup httpd and nginx
    05  memcached          to setup memcached
    06  mod_time           to setup mod_time
    07  rysnc_file         to setup rsync_file
    08  mariadb            to setup mariadb
    09  docker             to setup docker
    10  keepalived         to setup keepalived
    11  haproxy            to setup haproxy
    99  all                to run 01~99 all at once

examples:
        $0 setup prepare (or $0 setup 01)
        $0 setup 01 -vvv (or -v or -vv 显示详细信息)
        $0 setup 01 -C (测试运行)
EOF
}

_debug() {
    DEBUG="${@: -1}"
    case "$DEBUG" in
    -v)
        true
        ;;
    -vv)
        true
        ;;
    -vvv)
        true
        ;;
    -C)
        DEBUG="-C"
        unset ANSIBLE_LOG_PATH
        ;;
    -Cv)
        DEBUG="-C -v"
        unset ANSIBLE_LOG_PATH
        ;;
    -Cvv)
        DEBUG="-C -vv"
        unset ANSIBLE_LOG_PATH
        ;;
    -Cvvv)
        DEBUG="-C -vvv"
        unset ANSIBLE_LOG_PATH
        ;;
    *)
        DEBUG=""
        ;;
    esac
}

_vars() {
    date=$(date +%Y%m%d)
    src_file=""
    dest_file=""
    tags=""
    EXPIRY=4800h    # default cert will expire in 200 days
    USER_TYPE=admin # admin/view, admin=clusterrole:cluster-admin view=clusterrole:view
    USER_NAME=user
}

_addmaster() {
    # check new master's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 1
    }

    # check if the new master already exsited
    sed -n '/^\[kube_master/,/^\[kube_node/p' ../inventory/hosts | grep -E "^$2$|^$2 " && {
        _logger error "master $2 already existed!"
        return 2
    }

    # add '/usr/bin/python' soft link, needed in some OS (ubuntu 16.04+)
    # ssh "$2" ln -s /usr/bin/python3 /usr/bin/python || echo ""

    _logger info "add $2 into 'kube_master' group"
    MASTER_INFO="${@:2}"
    sed -i "/\[kube_master/a $MASTER_INFO" ../inventory/hosts

    _logger info "start to add a master node:$2 into cluster:k8s"
    ansible-playbook -i ../inventory/hosts ../playbooks/addmaster.yml -e "NODE_TO_ADD=$2" -e "@../config.yml"

    _logger info "reconfigure and restart 'kube-lb' service"
    ansible-playbook -i ../inventory/hosts ../playbooks/kube-config.yml -t create_kctl_cfg -e "@../config.yml"

    _logger info "reconfigure and restart 'ex-lb' service"
    ansible-playbook -i ../inventory/hosts ../playbooks/15.kube-master.yml -t restart_kube-lb -e "@../config.yml"
}

_delmaster() {
    # check node's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 2
    }

    # check if the deleting master exsited
    sed -n '/^\[kube_master/,/^\[kube_node/p' "../inventory/hosts" | grep -E "^$2$|^$2 " || {
        _logger error "master $2 not existed!"
        return 2
    }

    _logger warn "start to delete the master:$2 from cluster:k8s"
    ansible-playbook -i ../inventory/hosts ../playbooks/delmaster.yml -e "NODE_TO_DEL=$2" -e "@../config.yml"

    _logger info "reconfig kubeconfig in ansible manage node"
    ansible-playbook -i ../inventory/hosts ../playbooks/kube-config.yml -t create_kctl_cfg -e "@../config.yml"

    _logger info "reconfigure and restart 'kube-lb' service"
    ansible-playbook -i ../inventory/hosts ../playbooks/15.kube-master.yml -t restart_kube-lb -e "@../config.yml"
}

_addnode() {
    # check new node's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 1
    }

    # check if the new node already exsited
    sed -n '/^\[kube_master/,/^\[harbor/p' ../inventory/hosts | grep -E "^$2$|^$2 " && {
        _logger error "node $2 already existed in ../inventory/hosts"
        return 2
    }

    # add '/usr/bin/python' soft link, needed in some OS (ubuntu 16.04+)
    # ssh "$2" ln -s /usr/bin/python3 /usr/bin/python || echo ""

    _logger info "add $2 into 'kube_node' group"
    NODE_INFO="${@:2}"
    sed -i "/\[kube_node/a $NODE_INFO" ../inventory/hosts

    _logger info "start to add a work node:$2 into cluster:k8s"
    ansible-playbook -i ../inventory/hosts "../playbooks/addnode.yml" -e "NODE_TO_ADD=$2" -e "@../config.yml"
}

_delnode() {
    # check node's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 2
    }

    # check if the deleting node exsited
    sed -n '/^\[kube_master/,/^\[harbor/p' ../inventory/hosts | grep -E "^$2$|^$2 " || {
        _logger error "node $2 not existed in ../inventory/hosts"
        return 2
    }

    _logger warn "start to delete the node:$2 from cluster:k8s"
    ansible-playbook -i ../inventory/hosts "../playbooks/delnode.yml" -e "NODE_TO_DEL=$2" -e "@../config.yml"
}

_add_etcd() {
    # check new node's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 1
    }

    # check if the new node already exsited
    sed -n '/^\[etcd/,/^\[kube_master/p' ../inventory/hosts | grep -E "^$2$|^$2 " && {
        _logger error "etcd $2 already existed!"
        return 2
    }

    # add '/usr/bin/python' soft link, needed in some OS (ubuntu 16.04+)
    # ssh "$2" ln -s /usr/bin/python3 /usr/bin/python || echo ""

    _logger info "add $2 into 'etcd' group"
    ETCD_INFO="${@:2}"
    sed -i "/\[etcd/a $ETCD_INFO" ../inventory/hosts

    _logger info "start to add a etcd node:$2 into cluster:k8s"
    ansible-playbook -i ../inventory/hosts "../playbooks/addetcd.yml" -e "NODE_TO_ADD=$2" -e "@../config.yml"

    _logger info "reconfig &restart the etcd cluster"
    ansible-playbook -i ../inventory/hosts "../playbooks/13.etcd.yml" -t restart_etcd -e "@../config.yml"

    _logger info "restart apiservers to use the new etcd cluster"
    ansible-playbook -i ../inventory/hosts "../playbooks/15.kube-master.yml" -t restart_master -e "@../config.yml"
}

_del_etcd() {
    # check node's address regexp
    [[ $2 =~ ^(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})(\.(2(5[0-5]{1}|[0-4][0-9]{1})|[0-1]?[0-9]{1,2})){3}$ ]] || {
        _logger error "Invalid ip add:$2"
        return 1
    }

    # check if the deleting node exsited
    sed -n '/^\[etcd/,/^\[kube_master/p' ../inventory/hosts | grep -E "^$2$|^$2 " || {
        _logger error "etcd $2 not existed!"
        return 2
    }

    _logger warn "start to delete the etcd node:$2 from cluster:k8s"
    ansible-playbook -i ../inventory/hosts "../playbooks/deletcd.yml" -e "ETCD_TO_DEL=$2" -e "@../config.yml"

    _logger info "reconfig &restart the etcd cluster"
    ansible-playbook -i ../inventory/hosts "../playbooks/13.etcd.yml" -t restart_etcd -e "@../config.yml"

    _logger info "restart apiservers to use the new etcd cluster"
    ansible-playbook -i ../inventory/hosts "../playbooks/15.kube-master.yml" -t restart_master -e "@../config.yml"
}

_add_kcfg() {
    USER_NAME="$USER_NAME"-$(date +'%Y%m%d%H%M')
    _logger info "add-kcfg in cluster:k8s with user:$USER_NAME"
    ansible-playbook -i "../inventory/hosts" -e "@../config.yml" -e "CUSTOM_EXPIRY=$EXPIRY" \
        -e "USER_TYPE=$USER_TYPE" -e "USER_NAME=$USER_NAME" -e "ADD_KCFG=true" \
        -t add-kcfg "../playbooks/kube-config.yml"
}

_del_kcfg() {
    _logger info "del-kcfg in cluster:k8s with user:$USER_NAME"
    CRB=$(../files/clusters/k8s-01/bin/kubectl --kubeconfig="../files/clusters/k8s-01/kubectl.kubeconfig" get clusterrolebindings -ojsonpath="{.items[?(@.subjects[0].name == '$USER_NAME')].metadata.name}") &&
        ../files/clusters/k8s-01/bin/kubectl --kubeconfig="../files/clusters/k8s-01/kubectl.kubeconfig" delete clusterrolebindings "$CRB" &&
        /bin/rm -f "../files/clusters/k8s-01/ssl/users/$USER_NAME"*
}

_list_kcfg() {
    logger info "list-kcfg in cluster:$1"
    ADMINS=$(../files/clusters/k8s-01/bin/kubectl --kubeconfig="../files/clusters/k8s-01/kubectl.kubeconfig" get clusterrolebindings -ojsonpath='{.items[?(@.roleRef.name == "cluster-admin")].subjects[*].name}')
    VIEWS=$(../files/clusters/k8s-01/bin/kubectl --kubeconfig="../files/clusters/k8s-01/kubectl.kubeconfig" get clusterrolebindings -ojsonpath='{.items[?(@.roleRef.name == "view")].subjects[*].name}')
    ALL=$(../files/clusters/k8s-01/bin/kubectl --kubeconfig="../files/clusters/k8s-01/kubectl.kubeconfig" get clusterrolebindings -ojsonpath='{.items[*].subjects[*].name}')

    printf "\n%-30s %-15s %-20s\n" USER TYPE "EXPIRY(+8h if in Asia/Shanghai)"
    echo "---------------------------------------------------------------------------------"

    for u in $ADMINS; do
        if [[ $u =~ ^.*-[0-9]{12}$ ]]; then
            t=$(../files/bin/cfssl-certinfo -cert "../files/clusters/k8s-01/ssl/users/$u.pem" | grep not_after | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')
            printf "%-30s %-15s %-20s\n" "$u" cluster-admin "$t"
        fi
    done

    for u in $VIEWS; do
        if [[ $u =~ ^.*-[0-9]{12}$ ]]; then
            t=$(../files/bin/cfssl-certinfo -cert "../files/clusters/k8s-01/ssl/users/$u.pem" | grep not_after | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')
            printf "%-30s %-15s %-20s\n" "$u" view "$t"
        fi
    done

    for u in $ALL; do
        if [[ $u =~ ^.*-[0-9]{12}$ ]]; then
            [[ $ADMINS == *$u* ]] || [[ $VIEWS == *$u* ]] || {
                t=$(bin/cfssl-certinfo -cert "../files/clusters/k8s-01/ssl/users/$u.pem" | grep not_after | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')
                printf "%-30s %-15s %-20s\n" "$u" unknown "$t"
            }
        fi
    done
    echo ""
}

_setup() {
    case "$2" in
    00 | ping)
        PLAY_BOOK="00.ping.yml"
        ;;
    01 | prepare)
        PLAY_BOOK="01.prepare.yml"
        ;;
    02 | nginx)
        PLAY_BOOK="02.nginx.yml"
        ;;
    03 | httpd)
        PLAY_BOOK="03.httpd.yml"
        ;;
    04 | httpd_nginx)
        PLAY_BOOK="04.httpd_nginx.yml"
        ;;
    05 | memcached)
        PLAY_BOOK="05.memcached.yml"
        ;;
    06 | mod_time)
        PLAY_BOOK="06.mod_time.yml"
        ;;
    07 | rsync_file)
        PLAY_BOOK="07.rsync_file.yml"
        ;;
    08 | mariadb)
        PLAY_BOOK="08.mariadb.yml"
        ;;
    09 | docker)
        PLAY_BOOK="09.docker.yml"
        ;;
    10 | keepalived)
        PLAY_BOOK="10.keepalived.yml"
        ;;
    11 | haproxy)
        PLAY_BOOK="11.haproxy.yml"
        ;;
    12 | kube-pre)
        PLAY_BOOK="12.kube-pre.yml"
        ;;
    13 | etcd)
        PLAY_BOOK="13.etcd.yml"
        ;;
    14 | runtime)
        PLAY_BOOK="14.runtime.yml"
        ;;
    15 | kube-master)
        PLAY_BOOK="15.kube-master.yml"
        ;;
    16 | kube-node)
        PLAY_BOOK="16.kube-node.yml"
        ;;
    17 | kube-net)
        PLAY_BOOK="17.kube-net.yml"
        ;;
    18 | kube-addons)
        PLAY_BOOK="18.kube-addons.yml"
        ;;
    20 | kube-delmaster)
        PLAY_BOOK="20.delmaster.yml"
        ;;
    97 | scripts)
        PLAY_BOOK="97.scripts.yml"
        ;;
    99 | all)
        PLAY_BOOK="99.setup.yml"
        ;;
    *)
        _usage_setup
        exit 1
        ;;
    esac
}

_cmd() {
    case $1 in
    setup)
        _setup "$@"
        _debug "$@"
        _log
        if [ "$3" == "limit" ]; then
            cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml --limit $3 ../playbooks/$PLAY_BOOK $DEBUG"
        else
            cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml ../playbooks/$PLAY_BOOK $DEBUG"
        fi
        _logger info $cmd && $cmd
        ;;
    ping)
        cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml ../playbooks/${PLAY_BOOK:=00.ping.yml}"
        _logger info $cmd && $cmd
        ;;
    test)
        _debug "$@"
        cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml ../playbooks/${PLAY_BOOK:=98.test.yml} $DEBUG"
        _logger info $cmd && $cmd
        ;;
    scripts)
        _debug "$@"
        if [[ "$2" =~ "sh" ]]; then
            scripts_name="-e script_name=$2"
        else
            scripts_name="-e script_name=scripts.sh"
        fi
        cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml $scripts_name ../playbooks/${PLAY_BOOK:=97.scripts.yml} $DEBUG"
        _logger info $cmd && $cmd
        ;;
    rsync)
        PLAY_BOOK = "07.rsync_file.yml"
        _debug "$@"
        _log
        if [ "$2" == "limit" ]; then
            src_file="-e src_file=$4"
            dest_file="-e dest_file=$5"
            cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml --limit $3 $src_file $dest_file ../playbooks/$PLAY_BOOK $DEBUG"
        else
            src_file="-e src_file=$2"
            dest_file="-e dest_file=$3"
            cmd="ansible-playbook -i ../inventory/hosts -e @../config.yml $src_file $dest_file ../playbooks/$PLAY_BOOK $DEBUG"
        fi
        _logger info $cmd && $cmd
        ;;
    addmaster)
        _addmaster $@
        ;;
    delmaster)
        _delmaster $@
        ;;
    addnode)
        _addnode $@
        ;;
    delnode)
        _delnode $@
        ;;
    addetcd)
        _addetcd $@
        ;;
    deletcd)
        _deletcd $@
        ;;
    add_kcfg)
        _add_kcfg $@
        ;;
    del_kcfg)
        USER_NAME=${2:-user}
        _del_kcfg $@
        ;;
    list_kcfg)
        _list_kcfg
        ;;
    *)
        _usage
        exit 0
        ;;
    esac
}

_vars
_cmd "$@"
