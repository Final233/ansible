#/usr/bin/env bash

CONTACT="root@localhost"

_notify() {
    MAIL_SUBBECT="$(hostname) to be $1,VIP shift"
    MAIL_BODY="$(date +'%F %T'): VRRP transition,$(hostname) changed to be $1"
    echo "$MAIL_BODY" | mail -s "$MAIL_SUBBECT" $CONTACT
}

case $1 in
master)
    _notify master
    ;;
backup)
    _notify backup
    ;;
fault)
    _notify fault
    ;;
*)
    echo "Usage: $(basename $0) {master|backup|fault}"
    ;;
esac
