#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi

[ -d 'build_Module_LLM_ubuntu22_04_mini' ] || mkdir -p build_Module_LLM_ubuntu22_04_mini/ubuntu-base-22.04.5-base-arm64
sudo rm build_Module_LLM_ubuntu22_04_mini/axera-image -rf
./creat_Module_LLM_buidlroot_image.sh
sudo cp build_Module_LLM_buidlroot/buildroot/output/axera-image build_Module_LLM_ubuntu22_04_mini/ -a
[ -d 'build_Module_LLM_ubuntu22_04_mini/axera-image' ] || { echo "not found axera-image" && exit -1; }

pushd build_Module_LLM_ubuntu22_04_mini
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { wget http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-arm64.tar.gz ; mv ubuntu-base-22.04.5-base-arm64.tar.gz ../ubuntu-base-22.04.5-base-arm64.tar.gz ; }
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { echo "not found ubuntu-base-22.04.5-base-arm64.tar.gz" && exit -1; }
[ -d 'ubuntu-base-22.04.5-base-arm64' ] || mkdir ubuntu-base-22.04.5-base-arm64
tar -zxpf ../ubuntu-base-22.04.5-base-arm64.tar.gz -C ubuntu-base-22.04.5-base-arm64

ln -s ubuntu-base-22.04.5-base-arm64 rootfs

sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04/* rootfs/
[ -f '../local_deb_package/install.sh' ] && { sudo mkdir -p rootfs/var/deb-archives ; sudo cp --preserve=mode,timestamps -rf ../local_deb_package/* rootfs/var/deb-archives/ ; } 
[ -f '../local_pip_package/install.sh' ] && { sudo mkdir -p rootfs/var/pip-archives ; sudo cp --preserve=mode,timestamps -rf ../local_pip_package/* rootfs/var/pip-archives/ ; }

sudo chroot ubuntu-base-22.04.5-base-arm64/ /bin/bash -c 'echo "root:root" | chpasswd'

[ -f 'rootfs/etc/apt/sources.list.bak' ] || sudo cp rootfs/etc/apt/sources.list rootfs/etc/apt/sources.list.bak -a
sudo rm rootfs/etc/apt/sources.list && sudo touch rootfs/etc/apt/sources.list

sudo echo "deb [trusted=yes] file:/var/deb-archives ./" > rootfs/etc/apt/sources.list.d/local-repo.list


# sudo chroot rootfs/ /bin/bash -c 'apt update ; echo "tzdata tzdata/Areas select Asia" | debconf-set-selections ; echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive apt install vim net-tools network-manager i2c-tools lrzsz kmod iputils-ping openssh-server ifplugd whiptail -y --option=Dpkg::Options::="--force-confnew"'

cat <<EOF > rootfs/var/install.sh

apt update
echo "tzdata tzdata/Areas select Asia" | debconf-set-selections
echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive 
apt install vim net-tools network-manager i2c-tools lrzsz kmod iputils-ping openssh-server ifplugd whiptail avahi-daemon evtest usbutils -y --option=Dpkg::Options::="--force-confnew"
apt install ethtool resolvconf ifupdown -y --option=Dpkg::Options::="--force-confold"
apt install udev ssh rsyslog -y --option=Dpkg::Options::="--force-confold"
apt install tee-supplicant inetutils-ping iperf3 -y --option=Dpkg::Options::="--force-confold"

[ -f "/var/deb-archives/install.sh" ] && /bin/bash /var/deb-archives/install.sh 
EOF


sudo chroot rootfs/ /bin/bash /var/install.sh
[ -f "rootfs/var/deb-archives/install.sh" ] && sudo rm -rf rootfs/var/deb-archives
[ -f "rootfs/var/pip-archives/install.sh" ] && sudo rm -rf rootfs/var/pip-archives
sudo rm rootfs/var/install.sh
sudo cp ../../board/m5stack/overlay/usr/* rootfs/usr/ -a
sudo cp ../../board/m5stack/module_LLM/overlay/usr/* rootfs/usr/ -a
sudo cp --preserve=mode,timestamps -rf ../overlay_ubuntu22_04/* rootfs/

TARGET_ROOTFS_DIR=ubuntu-base-22.04.5-base-arm64

#modify for rtc ntp
sudo echo "*/1 *   * * *   root    /sbin/hwclock -w -f /dev/rtc0" >> $TARGET_ROOTFS_DIR/etc/crontab
sudo echo "*/1 *   * * *   root    sleep 60 && systemctl restart ntp" >> $TARGET_ROOTFS_DIR/etc/crontab

#remove this file or mac address will be modified all same
sudo rm $TARGET_ROOTFS_DIR/usr/lib/udev/rules.d/80-net-setup-link.rules

#modify dhclient timeout @baolin
sudo sed -i 's/timeout 300/timeout 5/g' $TARGET_ROOTFS_DIR/etc/dhcp/dhclient.conf
sudo sed -i 's/#retry 60/retry 3/g' $TARGET_ROOTFS_DIR/etc/dhcp/dhclient.conf

#modify networking service
sudo sed -i '/TimeoutStartSec=/s/.*/TimeoutStartSec=10sec/' $TARGET_ROOTFS_DIR/usr/lib/systemd/system/networking.service

#mv dev_ip_flush to directory
#mv dev_ip_flush $TARGET_ROOTFS_DIR/etc/network/if-post-down.d/

#modify "raise network interface fail"
sudo sed -i '/mystatedir statedir ifindex interface/s/^/#/' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i '/mystatedir statedir ifindex interface/s/^/#/' $TARGET_ROOTFS_DIR/etc/network/if-down.d/resolved
sudo sed -i '/return/s/return/exit 0/' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i '/return/s/return/exit 0/' $TARGET_ROOTFS_DIR/etc/network/if-down.d/resolved
sudo sed -i 's/DNS=DNS/DNS=\$DNS/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i 's/DOMAINS=DOMAINS/DOMAINS=\$DOMAINS/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i 's/DNS=DNS6/DNS=\$DNS6/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i 's/DOMAINS=DOMAINS6/DOMAINS=\$DOMAINS6/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i 's/"\$DNS"="\$NEW_DNS"/DNS="\$NEW_DNS"/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i 's/"\$DOMAINS"="\$NEW_DOMAINS"/DOMAINS="\$NEW_DOMAINS"/g' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved
sudo sed -i '/DNS DNS6 DOMAINS DOMAINS6 DEFAULT_ROUTE/s/^/#/' $TARGET_ROOTFS_DIR/etc/network/if-up.d/resolved

sync



sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' rootfs/etc/ssh/sshd_config
sudo rm rootfs/etc/apt/sources.list.d/local-repo.list
sudo cp rootfs/etc/apt/sources.list.bak rootfs/etc/apt/sources.list
sudo rm rootfs/var/deb-archives -rf
# sudo rm rootfs/etc/modprobe.d/blacklist* -rf


sudo cp axera-image/rootfs_sparse.ext4 rootfs_sparse.ext4
sudo simg2img rootfs_sparse.ext4 rootfs_.ext4
mkdir build_rootfs
sudo mount rootfs_.ext4 build_rootfs

sudo cp build_rootfs/lib/modules rootfs/lib/ -a
sudo cp build_rootfs/lib/firmware/* rootfs/lib/firmware/ -a

sudo rm rootfs/usr/bin/sh -f
sudo cp build_rootfs/bin/busybox rootfs/usr/bin/ -a
sudo cp build_rootfs/sbin/devmem rootfs/usr/sbin/ -a
sudo cp build_rootfs/sbin/hwclock rootfs/usr/sbin/ -a
sudo cp build_rootfs/bin/sh rootfs/usr/bin/ -a
sudo cp build_rootfs/usr/lib/libcrypto.so.1.1 rootfs/usr/lib/ -a

sudo umount build_rootfs
sudo rm build_rootfs rootfs_sparse.ext4 rootfs_.ext4 -rf



sudo tar zxf ../../board/m5stack/soc.tar.gz -C rootfs/soc
[ -f "../../board/m5stack/opt.tar.gz" ] && sudo tar zxf ../../board/m5stack/opt.tar.gz -C rootfs/opt

sudo find rootfs -name ".empty" -exec rm {} -f \;

sudo rm axera-image/rootfs_sparse.ext4
sudo ../bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s axera-image/rootfs_sparse.ext4 ubuntu-base-22.04.5-base-arm64/

cd axera-image
zip -r ../output.zip .
cd ..
mv output.zip M5_LLM_ubuntu22.04_$(date +%Y%m%d)_mini.axp

sudo rm rootfs ubuntu-base-22.04.5-base-arm64 -rf

popd
echo "$image_name creat success!"


