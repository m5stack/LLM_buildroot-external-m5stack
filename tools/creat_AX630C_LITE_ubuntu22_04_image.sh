#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi

[ -d 'build_Module_LITE_ubuntu22_04' ] || mkdir -p build_Module_LITE_ubuntu22_04/ubuntu-base-22.04.5-base-arm64
./creat_AX630C_LITE_buidlroot_image.sh && cp build_AX630C_LITE_buidlroot/buildroot/output/axera-image build_Module_LITE_ubuntu22_04/ -a
[ -d 'build_Module_LITE_ubuntu22_04/axera-image' ] || { echo "not found axera-image" && exit -1; }

pushd build_Module_LITE_ubuntu22_04
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { wget http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-arm64.tar.gz ; mv ubuntu-base-22.04.5-base-arm64.tar.gz ../ubuntu-base-22.04.5-base-arm64.tar.gz ; }
[ -f '../ubuntu-base-22.04.5-base-arm64.tar.gz' ] || { echo "not found ubuntu-base-22.04.5-base-arm64.tar.gz" && exit -1; }
[ -d 'ubuntu-base-22.04.5-base-arm64' ] || mkdir ubuntu-base-22.04.5-base-arm64
tar -zxpf ../ubuntu-base-22.04.5-base-arm64.tar.gz -C ubuntu-base-22.04.5-base-arm64

ln -s ubuntu-base-22.04.5-base-arm64 rootfs

sudo cp --preserve=mode,timestamps -r ../overlay_ubuntu22_04/* rootfs
sudo cp --preserve=mode,timestamps -r ../overlay_ubuntu22_04_LITE/* rootfs

sudo chroot ubuntu-base-22.04.5-base-arm64/ /bin/bash -c 'echo "root:root" | chpasswd'

[ -f 'rootfs/etc/apt/sources.list.bak' ] || sudo cp rootfs/etc/apt/sources.list rootfs/etc/apt/sources.list.bak -a
sudo rm rootfs/etc/apt/sources.list && sudo touch rootfs/etc/apt/sources.list

sudo echo "deb [trusted=yes] file:/var/deb-archives ./" > rootfs/etc/apt/sources.list.d/local-repo.list
sudo chroot rootfs/ /bin/bash -c 'apt update ; echo "tzdata tzdata/Areas select Asia" | debconf-set-selections ; echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections ; DEBIAN_FRONTEND=noninteractive apt install vim net-tools network-manager -y'

sudo rm rootfs/etc/apt/sources.list.d/local-repo.list
sudo cp rootfs/etc/apt/sources.list.bak rootfs/etc/apt/sources.list
sudo sed -i '1a 127.0.0.1       m5stack-LLM' rootfs/etc/hosts
sudo rm rootfs/var/deb-archives -rf

sudo rm axera-image/rootfs_sparse.ext4


sudo tar zxf ../board/m5stack/soc.tar.gz -C rootfs/soc


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
