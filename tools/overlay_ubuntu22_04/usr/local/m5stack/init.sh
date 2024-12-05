#!/bin/bash
/sbin/modprobe fb_ili9342c
. /usr/local/m5stack/bashrc
printf "q\r\n" | fbv /usr/local/m5stack/logo.jpg > /dev/null 2>&1 &
/usr/local/m5stack/lt8618sxb_mcu_config  > dev/null 2>&1 &
echo 1 4 1 7 > /proc/sys/kernel/printk
tinyplay /usr/local/m5stack/logo.wav > /dev/null 2>&1 &



