#!/bin/sh
. /etc/profile
/usr/local/m5stack/bin/ax_usb_adb_event.sh >> /dev/null 2>&1 &
if [ ! -f '/var/cmm_switch.lock' ] ; then
	ddr_mem_start=1073741824
	CMM_VALUE=$(grep 'insmod /soc/ko/ax_cmm.ko cmmpool=anonymous' "/soc/scripts/auto_load_all_drv.sh" | sed -n 's/.*cmmpool=anonymous,0,0x[0-9A-Fa-f]*,\([0-9]*\)M.*/\1/p')
	MEM_VALUE=$(grep -o 'mem=[0-9]*M' /proc/cmdline | sed 's/mem=\([0-9]*\)M/\1/')
	ALL_MEM=4096
	input=2048
	NEW_CMM_VALUE=$(expr $ALL_MEM - $input)
	NEW_MEM_VALUE=$input
	tmp_val=$(expr $NEW_MEM_VALUE \* 1024 \* 1024)
	CMM_DDR_START=$(expr $ddr_mem_start + $tmp_val)
	ax_cmm_ko_cmd=$(printf 's|cmmpool=anonymous,0,0x[0-9A-Fa-f]\{7,8\},[0-9]\{1,4\}M|cmmpool=anonymous,0,0x%X,%dM|' $CMM_DDR_START $NEW_CMM_VALUE)
	sed -i "$ax_cmm_ko_cmd" /soc/scripts/auto_load_all_drv.sh
	cmdline=$(cat /proc/cmdline)
	new_cmdline=$(echo "$cmdline" | sed -E "s/mem=[0-9]+M/mem=${NEW_MEM_VALUE}M/")
	fw_setenv bootargs "$new_cmdline"
	touch /var/cmm_switch.lock
	sync
    /usr/sbin/m5stack_esp_flasher /lib/firmware/esphosted_c6/esphosted_ng_sdio.bin
    touch /var/espc6wifi.config
    sync
fi



exit 0
