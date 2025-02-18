#!/bin/sh
. /etc/profile
[ -f '/etc/ld.so.conf.d/libaxengine.conf' ] || echo '/opt/lib' > /etc/ld.so.conf.d/libaxengine.conf
start-stop-daemon --start --quiet --background --make-pidfile --pidfile /tmp/ax_usb_adb_event.pid --exec /usr/local/m5stack/bin/ax_usb_adb_event.sh
insmod /usr/lib/modules/4.19.125/kernel/drivers/leds/led-class.ko
insmod /usr/lib/modules/4.19.125/kernel/drivers/leds/leds-lp55xx-common.ko
insmod /usr/lib/modules/4.19.125/kernel/drivers/leds/leds-lp5562.ko
sleep 0.1
echo 0  > /sys/class/leds/R/brightness
echo 50 > /sys/class/leds/G/brightness
echo 0  > /sys/class/leds/B/brightness
tinyplay -D0 -d1 /usr/local/m5stack/logo.wav > /dev/null 2>&1 &
exit 0

