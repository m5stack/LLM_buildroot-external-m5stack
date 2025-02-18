#!/bin/sh
. /etc/profile
if [ -d '/etc/ld.so.conf.d' ] ; then
    if [ ! -f '/etc/ld.so.conf.d/libaxengine.conf' ] ; then
        echo '/opt/lib' > /etc/ld.so.conf.d/libaxengine.conf
        ldconfig
    fi
fi
start-stop-daemon --start --quiet --background --make-pidfile --pidfile /tmp/ax_usb_adb_event.pid --exec /usr/local/m5stack/bin/ax_usb_adb_event.sh

exit 0
