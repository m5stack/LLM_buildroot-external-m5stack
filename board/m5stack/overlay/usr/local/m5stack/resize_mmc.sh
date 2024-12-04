#!/bin/sh

sgdisk /dev/mmcblk0 -p
sgdisk -d 5 /dev/mmcblk0
sgdisk -a 1 -n 5:`expr $(sgdisk /dev/mmcblk0 -i 4 | grep "Last sector" | awk '{print $3}') + 1`:  -c 5:rootfs -t 5:8300  -u 5:549C80E0-A7FA-42CB-87B7-810481D4D26F /dev/mmcblk0
sgdisk /dev/mmcblk0 -A 5:set:2
fsck -f /dev/mmcblk0p5
resize2fs /dev/mmcblk0p5
sgdisk /dev/mmcblk0 -p
sgdisk /dev/mmcblk0 -i 5

echo "#!/bin/sh

start() {
    /sbin/resize2fs /dev/mmcblk0p5
    sync
    /bin/sh -c \"sleep 1; rm /etc/init.d/S40resizefs\" &
}
stop() {
	echo \"no\" > /dev/null
}
restart() {
	stop
	start
}

case \"\$1\" in
  start)
  	start
	;;
  stop)
  	stop
	;;
  restart|reload)
  	restart
	;;
  *)
	echo \"Usage: \$0 {start|stop|restart}\"
	exit 1
esac

exit \$?

" > /etc/init.d/S40resizefs
chmod +x /etc/init.d/S40resizefs

sync
echo "Please restart! "

