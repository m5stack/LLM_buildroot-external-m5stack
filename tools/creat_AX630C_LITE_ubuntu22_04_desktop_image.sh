#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi


[ -d 'build_AX630C_LITE_ubuntu22_04' ] || mkdir -p build_AX630C_LITE_ubuntu22_04/ubuntu-base-22.04.5-base-arm64
./creat_AX630C_LITE_buidlroot_image.sh && sudo cp build_AX630C_LITE_buidlroot/buildroot/output/axera-image build_AX630C_LITE_ubuntu22_04/ -a
[ -d 'build_AX630C_LITE_ubuntu22_04/axera-image' ] || { echo "not found axera-image" && exit -1; }

pushd build_AX630C_LITE_ubuntu22_04
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { wget http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-arm64.tar.gz ; mv ubuntu-base-22.04.5-base-arm64.tar.gz ../ubuntu-base-22.04.5-base-arm64.tar.gz ; }
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { echo "not found ubuntu-base-22.04.5-base-arm64.tar.gz" && exit -1; }
[ -d 'ubuntu-base-22.04.5-base-arm64' ] || mkdir ubuntu-base-22.04.5-base-arm64
tar -zxpf ../ubuntu-base-22.04.5-base-arm64.tar.gz -C ubuntu-base-22.04.5-base-arm64

ln -s ubuntu-base-22.04.5-base-arm64 rootfs

sudo cp --preserve=mode,timestamps -r ../overlay_ubuntu22_04/* rootfs
sudo cp --preserve=mode,timestamps -r ../overlay_ubuntu22_04_LITE/* rootfs
sudo cp --preserve=mode,timestamps -r ../overlay_ubuntu22_04_LITE_desktop/* rootfs

sudo chroot ubuntu-base-22.04.5-base-arm64/ /bin/bash -c 'echo "root:root" | chpasswd'

sudo cp /etc/resolv.conf rootfs/etc/
cat <<EOF > rootfs/var/build.sh
[ -f '/etc/apt/sources.list.bak' ] || cp /etc/apt/sources.list /etc/apt/sources.list.bak -a
rm /etc/apt/sources.list 
touch /etc/apt/sources.list
echo "deb [trusted=yes] file:/var/deb-archives ./" > /etc/apt/sources.list.d/local-repo.list
apt update
echo "tzdata tzdata/Areas select Asia" | debconf-set-selections
echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install vim net-tools network-manager i2c-tools lrzsz kmod iputils-ping openssh-server ifplugd -y --option=Dpkg::Options::="--force-confnew"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
rm /etc/apt/sources.list.d/local-repo.list
cp /etc/apt/sources.list.bak rootfs/etc/apt/sources.list


chmod 777 /tmp

apt-get update --allow-insecure-repositories

yes | apt-get install cmake build-essential

yes | apt-get install python3-pip

yes | apt-get install fbset xfce4 lxdm
yes | apt-get purge xfce4-screensaver
yes | apt-get autoremove
yes | apt-get install xfce4-power-manager

yes | apt install software-properties-common
yes | add-apt-repository ppa:mozillateam/ppa
apt-get update
yes | apt install --target-release 'o=LP-PPA-mozillateam' firefox
yes | apt-get install fonts-wqy-zenhei

yes | apt-get install nfs-common
yes | apt-get install openbsd-inetd
yes | apt-get install telnetd

mandb -csp

#exit and clean
apt clean
sync
history -c

EOF

sudo chroot rootfs/ /bin/bash /var/build.sh


sudo sed -i '1a 127.0.0.1       m5stack-LLM' rootfs/etc/hosts
sudo rm rootfs/var/deb-archives -rf
# sudo rm rootfs/etc/modprobe.d/blacklist* -rf

sudo cp ../../board/m5stack/overlay/usr/* rootfs/usr/ -a

sudo cp axera-image/rootfs_sparse.ext4 rootfs_sparse.ext4
sudo simg2img rootfs_sparse.ext4 rootfs_.ext4
mkdir build_rootfs
sudo mount rootfs_.ext4 build_rootfs

sudo cp build_rootfs/lib/modules rootfs/lib/ -a
sudo cp build_rootfs/lib/firmware/* rootfs/lib/firmware/ -a

sudo rm rootfs/usr/bin/sh -f
sudo cp build_rootfs/bin/busybox rootfs/usr/bin/ -a
sudo cp build_rootfs/sbin/devmem rootfs/usr/sbin/ -a
sudo cp build_rootfs/bin/sh rootfs/usr/bin/ -a
sudo cp build_rootfs/usr/lib/libcrypto.so.1.1 rootfs/usr/lib/ -a

sudo umount build_rootfs
sudo rm build_rootfs rootfs_sparse.ext4 rootfs_.ext4 -rf

sudo tar zxf ../../board/m5stack/soc.tar.gz -C rootfs/soc
[ -f "../../board/m5stack/opt.tar.gz" ] && sudo tar zxf ../../board/m5stack/opt.tar.gz -C rootfs/opt

sudo find rootfs -name ".empty" -exec rm {} -f \;

TARGET_ROOTFS_DIR=rootfs

#modify lxdm config
sed -i 's/\/usr\/share\/images\/desktop-base\/login-background.svg/\/usr\/share\/backgrounds\/xfce\/xfce-verticals.png/g' $TARGET_ROOTFS_DIR/etc/lxdm/lxdm.conf
sed -i 's/bottom_pane=1/bottom_pane=0/g' $TARGET_ROOTFS_DIR/etc/lxdm/lxdm.conf
sed -i 's/# autologin=dgod/autologin=root/g' $TARGET_ROOTFS_DIR/etc/lxdm/lxdm.conf
sed -i 's/disable=0/disable=1/g' $TARGET_ROOTFS_DIR/etc/lxdm/lxdm.conf
sed -i 's/# session=\/usr\/bin\/startlxde/session=\/usr\/bin\/startxfce4/g' $TARGET_ROOTFS_DIR/etc/lxdm/lxdm.conf

#change the default browser to firefox
sed -i 's/debian-sensible-browser/firefox/g' $TARGET_ROOTFS_DIR/etc/xdg/xfce4/helpers.rc
sed -i 's/debian-x-terminal-emulator/gnome-terminal/g' $TARGET_ROOTFS_DIR/etc/xdg/xfce4/helpers.rc

#modify audio config
sed -i 's/ConditionUser=!root/#ConditionUser=!root/g' $TARGET_ROOTFS_DIR/usr/lib/systemd/user/pulseaudio.service
sed -i 's/ConditionUser=!root/#ConditionUser=!root/g' $TARGET_ROOTFS_DIR/usr/lib/systemd/user/pulseaudio.socket
mv $TARGET_ROOTFS_DIR/usr/share/pulseaudio/alsa-mixer/profile-sets/default.conf $TARGET_ROOTFS_DIR/usr/share/pulseaudio/alsa-mixer/profile-sets/default.back
sed -i 's/; default-sample-rate = 44100/default-sample-rate = 48000/g' $TARGET_ROOTFS_DIR/etc/pulse/daemon.conf
sed -i '/### Automatically load driver modules depending on the hardware available/i load-module module-alsa-sink device=hw:0,1' $TARGET_ROOTFS_DIR/etc/pulse/default.pa
sed -i '/### Automatically load driver modules depending on the hardware available/i load-module module-alsa-source device=hw:0,0' $TARGET_ROOTFS_DIR/etc/pulse/default.pa


#modify upower config
sed -i 's/PrivateUsers=yes/#PrivateUsers=yes/g' $TARGET_ROOTFS_DIR/usr/lib/systemd/system/upower.service
sed -i 's/RestrictNamespaces=yes/#RestrictNamespaces=yes/g' $TARGET_ROOTFS_DIR/usr/lib/systemd/system/upower.service


#first boot
echo 'file="/etc/firstboot"' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo 'if [ -f "$file" ]; then' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo '    :' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo 'else' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo '    ldconfig' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo '    mandb -csp' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo '    touch "$file"' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo 'fi' >> $TARGET_ROOTFS_DIR/etc/rc.local


#start desktop
echo 'export LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:/opt/lib:/soc/lib"' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo 'bash /root/startDesktop.sh' >> $TARGET_ROOTFS_DIR/etc/rc.local
echo 'dhclient' >> $TARGET_ROOTFS_DIR/etc/rc.local

sync

sudo rm axera-image/rootfs_sparse.ext4
sudo ../bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s axera-image/rootfs_sparse.ext4 ubuntu-base-22.04.5-base-arm64/

cd axera-image
zip -r ../output.zip .
cd ..
mv output.zip M5_LLM_ubuntu22.04_$(date +%Y%m%d).axp

sudo rm rootfs ubuntu-base-22.04.5-base-arm64 -rf

popd
echo "$image_name creat success!"








# sudo losetup -P /dev/loop258 sdcard.img
# sleep 1
# [ -e "/dev/loop258p5" ] || { echo "not found /dev/loop258p5" && exit -1; }
# sudo mount /dev/loop258p5 rootfs

# mkdir -p rootfs_overlay ;sudo cp rootfs/boot rootfs_overlay/ -a
# mkdir -p rootfs_overlay/usr/lib ;sudo cp rootfs/lib/modules rootfs_overlay/usr/lib/ -a
# mkdir -p rootfs_overlay/usr/lib ;sudo cp rootfs/lib/firmware rootfs_overlay/usr/lib/ -a

# mkdir -p rootfs_overlay/usr/local/m5stack/bin ;sudo cp rootfs/usr/bin/tiny* rootfs_overlay/usr/local/m5stack/bin/ -a
# mkdir -p rootfs_overlay/usr/local/m5stack/bin ;sudo cp rootfs/usr/bin/fbv rootfs_overlay/usr/local/m5stack/bin/ -a

# mkdir -p rootfs_overlay/usr/local/m5stack/lib ;sudo cp rootfs/usr/lib/libtinyalsa* rootfs_overlay/usr/local/m5stack/lib/ -a
# mkdir -p rootfs_overlay/usr/local/m5stack/lib ;sudo cp rootfs/usr/lib/libpng16* rootfs_overlay/usr/local/m5stack/lib/ -a
# mkdir -p rootfs_overlay/usr/local/m5stack/lib ;sudo cp rootfs/usr/lib/libjpeg* rootfs_overlay/usr/local/m5stack/lib/ -a
# mkdir -p rootfs_overlay/usr/local/m5stack/lib ;sudo cp rootfs/usr/lib/libgif* rootfs_overlay/usr/local/m5stack/lib/ -a

# sudo rm rootfs/* -rf
# sudo tar xf ubuntu-base-22.04.5-base-arm64/debian-12.1-minimal-armhf-2023-08-22/armhf-rootfs-debian-bookworm.tar -C rootfs/

# sudo cp --preserve=mode,timestamps -r rootfs_overlay/* rootfs/
# sudo cp --preserve=mode,timestamps -r ../overlay_debian12/* rootfs/
# sudo rm rootfs/etc/systemd/system/multi-user.target.wants/nginx.service
# sudo rm rootfs/etc/systemd/system/multi-user.target.wants/networking.service
# sudo rm rootfs/etc/systemd/system/network-online.target.wants/networking.service
# sudo sed -i '1a 127.0.0.1       CoreMP135' rootfs/etc/hosts

# sudo chroot rootfs/ /usr/bin/dpkg -i /var/gdisk_1.0.9-2.1_armhf.deb
# sudo chroot rootfs/ /usr/bin/dpkg -i /var/network-manager_1.42.4-1_armhf.deb


# sudo sync
# sudo umount rootfs
# sudo losetup -D /dev/loop258

# date_str=`date +%Y%m%d`
# image_name="M5_Module_LLM_ubuntu22_04_$date_str.img"
# mv sdcard.img $image_name

# popd
# echo "$image_name creat success!"
