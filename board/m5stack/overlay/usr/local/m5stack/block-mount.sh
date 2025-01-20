#!/bin/bash
# /etc/hotplug.d/block/10-block
LOGGER=/usr/bin/logger
BLACKLIST=""
WHITELIST=""

DEVNAME=$(basename "$DEVNAME")

is_in_list() {
    local item=$1
    local list=$2
    for i in $list; do
        if [ "$i" = "$item" ]; then
            return 0
        fi
    done
    return 1
}

case "$ACTION" in
    add)
        $LOGGER "Block device added: $DEVNAME"
        if echo "$DEVNAME" | grep -qE '^(mmcblk[1-9]+p[0-9]+|sd[a-z][0-9]+)$'; then
            $LOGGER "Device $DEVNAME is of supported type"
            
            if is_in_list "$DEVNAME" "$BLACKLIST"; then
                $LOGGER "Device $DEVNAME is in the blacklist, ignoring."
                exit 0
            fi
            
            if [ -n "$WHITELIST" ]; then
                if ! is_in_list "$DEVNAME" "$WHITELIST"; then
                    $LOGGER "Device $DEVNAME is not in the whitelist, ignoring."
                    exit 0
                fi
            fi
            
            mkdir -p /mnt/$DEVNAME
            # mount /dev/$DEVNAME /mnt/$DEVNAME
	        /usr/bin/systemd-mount --no-block --collect /dev/$DEVNAME /mnt/$DEVNAME
            if [ $? -eq 0 ]; then
                $LOGGER "Successfully mounted /dev/$DEVNAME to /mnt/$DEVNAME"
                if [ ! -f "/tmp/update_check_script.lock" ] ; then
                    touch /tmp/update_check_script.lock
                    sync
                    /usr/bin/systemd-run --unit=update_check --quiet /usr/local/m5stack/update_check.sh
                fi
            else
                $LOGGER "Failed to mount /dev/$DEVNAME"
            fi
        else
            $LOGGER "Device $DEVNAME is not of supported type"
        fi
        ;;
    remove)
        $LOGGER "Block device removed: $DEVNAME"
        if echo "$DEVNAME" | grep -qE '^(mmcblk[1-9]+p[0-9]+|sd[a-z][0-9]+)$'; then
            $LOGGER "Device $DEVNAME is of supported type"
            
            if is_in_list "$DEVNAME" "$BLACKLIST"; then
                $LOGGER "Device $DEVNAME is in the blacklist, ignoring."
                exit 0
            fi
            
            if [ -n "$WHITELIST" ]; then
                if ! is_in_list "$DEVNAME" "$WHITELIST"; then
                    $LOGGER "Device $DEVNAME is not in the whitelist, ignoring."
                    exit 0
                fi
            fi
            
            #umount /mnt/$DEVNAME
	        /usr/bin/systemd-umount /mnt/$DEVNAME
            if [ $? -eq 0 ]; then
                $LOGGER "Successfully unmounted /mnt/$DEVNAME"
            else
                $LOGGER "Failed to unmount /mnt/$DEVNAME"
            fi
            rmdir /mnt/$DEVNAME
        else
            $LOGGER "Device $DEVNAME is not of supported type"
        fi
        ;;
    *)
        $LOGGER "Unhandled action: $ACTION"
        ;;
esac


# [ "$ACTION" = "add" -o "$ACTION" = "remove" ] && /sbin/block hotplug

