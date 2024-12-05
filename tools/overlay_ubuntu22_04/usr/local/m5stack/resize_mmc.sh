#!/bin/bash

device="/dev/mmcblk0"
sgdisk ${device} -p
sgdisk -d 5 ${device}
sgdisk -a 1 -n 5:`expr $(sgdisk ${device} -i 4 | grep "Last sector" | awk '{print $3}') + 1`:  -c 5:rootfs -t 5:8300  -u 5:549C80E0-A7FA-42CB-87B7-810481D4D26F ${device}
sgdisk ${device} -A 5:set:2
fsck -f ${device}p5
resize2fs ${device}p5
sgdisk ${device} -p
sgdisk ${device} -i 5
echo "

[Unit]
Description=Resize root filesystem to fit available disk space
Wants=systemd-udevd.service systemd-udev-trigger.service
After=systemd-remount-fs.service systemd-udevd.service

[Service]
Type=oneshot
ExecStart=/sbin/resize2fs ${device}p5
ExecStartPost=/bin/systemctl disable resizefs.service

[Install]
WantedBy=basic.target

" > /etc/systemd/system/resizefs.service

systemctl enable resizefs.service
sync
echo "Please restart! "
