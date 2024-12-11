#!/bin/sh

while true; do
    if [ -z "$(cat /etc/configfs/usb_gadget/usb_adb/UDC)" ]; then
        echo "8000000.dwc3" > /etc/configfs/usb_gadget/usb_adb/UDC
    fi
    sleep 1
done