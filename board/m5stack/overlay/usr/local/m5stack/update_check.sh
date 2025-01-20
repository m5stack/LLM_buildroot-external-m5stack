#!/bin/bash
sleep 5
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/usr/bin:/opt/scripts:/soc/bin:/soc/scripts:/usr/local/bin
LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/opt/lib:/opt/usr/lib:/soc/lib
update_file=$(find /mnt -name "m5stack_update.config")
LOGFILE=${update_file}.update.log
echo "find ${update_file} " > $LOGFILE
if [ -n "$update_file" ] ; then
    echo "start update .." >> $LOGFILE
    blank_pid="0"
    if [ "`hostname`" = "m5stack-LLM" ] ; then
        echo 0  > /sys/class/leds/R/brightness
        echo 0 > /sys/class/leds/G/brightness
        echo 0  > /sys/class/leds/B/brightness
        sleep 0.1
        bash -c "while true ; do echo 0  > /sys/class/leds/B/brightness ; sleep 0.5; echo 50  > /sys/class/leds/B/brightness ; sleep 0.5 ; done " &
        blank_pid=$!
    else
        bash -c "while true ; do echo 0  > /sys/class/leds/sys_led/brightness ; sleep 0.5; echo 255  > /sys/class/leds/sys_led/brightness ; sleep 0.5 ; done " &
        blank_pid=$!
    fi
    dir_path=$(dirname "$update_file")

    success_flag=1
    while IFS= read -r line; do
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        if [[ "$line" =~ deb$ ]]; then
            echo "install ${dir_path}/$line .." >>  $LOGFILE
            dpkg -i ${dir_path}/$line >> $LOGFILE 2>&1
            if [ "$?" -ne 0 ] ; then 
                success_flag=0
            fi
        fi
    fi
    done < "$update_file"

    [ "$blank_pid" = "0" ] || kill $blank_pid

    if [ "`hostname`" = "m5stack-LLM" ] ; then
        if [ "$success_flag" -eq 1 ] ; then 
            echo "all package update success!" >> $LOGFILE
            echo 0  > /sys/class/leds/R/brightness
            echo 50 > /sys/class/leds/G/brightness
            echo 0  > /sys/class/leds/B/brightness
        else
            echo "package update false!" >> $LOGFILE
            echo 50  > /sys/class/leds/R/brightness
            echo 0 > /sys/class/leds/G/brightness
            echo 0  > /sys/class/leds/B/brightness
        fi
    else
        if [ "$success_flag" -eq 1 ] ; then 
            echo "all package update success!" >> $LOGFILE
            echo 255  > /sys/class/leds/sys_led/brightness
        else
            echo "package update false!" >> $LOGFILE
            echo 0  > /sys/class/leds/sys_led/brightness
        fi
    fi
fi
rm /tmp/update_check_script.lock
sync