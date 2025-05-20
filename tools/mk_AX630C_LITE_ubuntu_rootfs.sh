#!/bin/bash
sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git cmake p7zip-full python3 python3-pip expect libssl-dev qemu-user-static android-sdk-libsparse-utils -y


project_name=AX630C_LITE_ubuntu22_04_rootfs
work_dir="build_${project_name}"
BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS="http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-arm64.tar.gz"
BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256="075d4abd2817a5023ab0a82f5cb314c5ec0aa64a9c0b40fd3154ca3bfdae979f"
BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME="ubuntu-base-22.04.5-base-arm64"


[ -d "$work_dir" ] || mkdir -p $work_dir
pushd $work_dir
if echo "$BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS" | grep -q "^http"; then
    [ -f "${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256}-ubuntu-base-22.04.5-base-arm64.tar.gz" ] || wget --passive-ftp -nd -t 3 -O "${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256}-ubuntu-base-22.04.5-base-arm64.tar.gz" "${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS}"
    BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS="${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256}-ubuntu-base-22.04.5-base-arm64.tar.gz"
    actual_sha256=$(sha256sum "$BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS" | awk '{print $1}')
    if [ "$actual_sha256" != "$BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256" ]; then
        echo "Verification failed: The SHA256 value of the file ${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS} does not match."
        echo "Expected value: $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_SAH256"
        echo "Actual value: $actual_sha256"
        rm ${BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS}
        exit 3
    fi
fi

# 解压
[ -d "$BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME" ] || mkdir -p $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME
tar -zxpf $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS -C $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME

# 复制 overlay 文件
sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/
sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04_LITE/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/
[ -f '../local_deb_package/install.sh' ] && { sudo mkdir -p $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/deb-archives ; sudo cp --preserve=mode,timestamps -rf ../local_deb_package/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/deb-archives/ ; } 
[ -f '../local_pip_package/install.sh' ] && { sudo mkdir -p $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/pip-archives ; sudo cp --preserve=mode,timestamps -rf ../local_pip_package/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/pip-archives/ ; }

# 执行安装程序
[ -f "$BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list.bak" ] || sudo cp $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list.bak -a
sudo rm $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list && sudo touch $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list
sudo echo "deb [trusted=yes] file:/var/deb-archives ./" > $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list.d/local-repo.list
cat <<EOF > $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/install.sh
apt update
echo "tzdata tzdata/Areas select Asia" | debconf-set-selections ; 
echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections ; 
export DEBIAN_FRONTEND=noninteractive ; 
apt install vim net-tools network-manager i2c-tools lrzsz kmod iputils-ping openssh-server ifplugd whiptail avahi-daemon evtest usbutils -y --option=Dpkg::Options::="--force-confnew"
apt install bash-completion sudo ethtool resolvconf ifupdown isc-dhcp-server -y --option=Dpkg::Options::="--force-confold"
apt install language-pack-en-base htop bc udev ssh rsyslog -y --option=Dpkg::Options::="--force-confold"
apt install tee-supplicant inetutils-ping iperf3 -y --option=Dpkg::Options::="--force-confold"
apt install python3-pip libgl1 -y

[ -f "/var/deb-archives/install.sh" ] && /var/deb-archives/install.sh 
[ -f "/var/pip-archives/install.sh" ] && /var/pip-archives/install.sh

echo "root:root" | chpasswd
EOF

sudo chroot $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/ /bin/bash /var/install.sh

sudo cp ../../board/m5stack/overlay/usr/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/usr/ -a
sudo cp ../../board/m5stack/module_kit/overlay/usr/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/usr/ -a
sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/
sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04_LITE/* $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/

# 清理安装文件
sudo rm -rf $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/install.sh $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/deb-archives $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/deb-archives $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/var/pip-archives 
sudo rm $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list.d/local-repo.list
sudo cp $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list.bak $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/apt/sources.list

# 系统微调
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/ssh/sshd_config

#modify for rtc ntp
sudo echo "*/1 *   * * *   root    /sbin/hwclock -w -f /dev/rtc0" >> $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/crontab
sudo echo "*/1 *   * * *   root    sleep 60 && systemctl restart ntp" >> $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/crontab

#remove this file or mac address will be modified all same
sudo rm $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/usr/lib/udev/rules.d/80-net-setup-link.rules

#modify dhclient timeout @baolin
sudo sed -i 's/timeout 300/timeout 5/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/dhcp/dhclient.conf
sudo sed -i 's/#retry 60/retry 3/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/dhcp/dhclient.conf

#modify networking service
sudo sed -i '/TimeoutStartSec=/s/.*/TimeoutStartSec=10sec/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/usr/lib/systemd/system/networking.service

#mv dev_ip_flush to directory
#mv dev_ip_flush $TARGET_ROOTFS_DIR/etc/network/if-post-down.d/

#modify "raise network interface fail"
sudo sed -i '/mystatedir statedir ifindex interface/s/^/#/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i '/mystatedir statedir ifindex interface/s/^/#/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-down.d/resolved
sudo sed -i '/return/s/return/exit 0/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i '/return/s/return/exit 0/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-down.d/resolved
sudo sed -i 's/DNS=DNS/DNS=\$DNS/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i 's/DOMAINS=DOMAINS/DOMAINS=\$DOMAINS/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i 's/DNS=DNS6/DNS=\$DNS6/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i 's/DOMAINS=DOMAINS6/DOMAINS=\$DOMAINS6/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i 's/"\$DNS"="\$NEW_DNS"/DNS="\$NEW_DNS"/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i 's/"\$DOMAINS"="\$NEW_DOMAINS"/DOMAINS="\$NEW_DOMAINS"/g' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved
sudo sed -i '/DNS DNS6 DOMAINS DOMAINS6 DEFAULT_ROUTE/s/^/#/' $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME/etc/network/if-up.d/resolved

sync

pushd $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME
sudo tar -zcf ../${project_name}.tar.gz .
popd
sudo rm -rf $BR2_M5STACK_BSP_SUPPORT_UBUNTU_ROOTFS_NAME
sync
popd

echo "--------------------------------------ubuntu rootfs build end--------------------------------------"










