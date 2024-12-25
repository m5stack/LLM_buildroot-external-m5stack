#! /bin/bash

Prog=/root/fb_vo

killDesk() {
        pid=`which $Prog | xargs lsof -Fp`
        if [ -n "$pid" ];then
                echo "Stopping [${pid##p}] $Prog..."
                kill -9 ${pid##p}
        fi
        systemctl stop lxdm
        echo "$Prog has been stopped."
}

restartDesk() {
        fbset -fb /dev/fb0 -xres 1920 -yres 1080 -vxres 1920 -vyres 2160 -depth 32 -rgba 8/16,8/8,8/0,8/24
        pid=`which $Prog | xargs lsof -Fp`
        if [ -z "$pid" ];then
                $Prog &
        fi
        systemctl restart lxdm
        echo "$Prog has been started."
}

echo $$
if [ -x $Prog ];then
        if [ 0 -ne $# ];then
                killDesk
                params=($@)
                target=${params[0]}
                target=`which $target`
                if [ -x $target ];then
                {
                        sleep 0.1
                        $target ${params[@]:1} >/dev/null 2>&1 &
                        pid=$!
                        echo [$pid] exec \"${params[*]}\"
                        while [ -d "/proc/$pid" ];do sleep 3;done
                        echo [$pid] \"${params[*]}\" exited
                        restartDesk
                }&
                echo outter $!
                fi
        else
                killDesk
                restartDesk
                # systemctl restart lxdm
        fi
fi

