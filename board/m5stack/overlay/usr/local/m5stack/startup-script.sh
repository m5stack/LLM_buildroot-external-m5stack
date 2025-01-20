#!/bin/sh
. /etc/profile
start-stop-daemon --start --quiet --background --make-pidfile --pidfile /tmp/ax_usb_adb_event.pid --exec /usr/local/m5stack/bin/ax_usb_adb_event.sh

exit 0
