#!/bin/bash -x
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT
export LLM_WORK_DIR='build_AX8850_buildroot'
export EXT_BOARD_NAME="_AX8850"
if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi

work_dir=build_AX8850_ubuntu22_04
ubuntu_rootfs_path="build_AX8850_ubuntu22_04_rootfs/AX8850_ubuntu22_04_rootfs.tar.gz"
BUILDROOTFS_OUTPUT_PATH="../build_AX8850_buildroot/buildroot/output"

[ -d "work_dir" ] || mkdir -p $work_dir

./creat_AX8850_buildroot_image.sh
[ -f "$ubuntu_rootfs_path" ] || sudo ./mk_AX8850_ubuntu_rootfs.sh
pushd $work_dir
[ -d "$BUILDROOTFS_OUTPUT_PATH/axera-image" ] && cp -rf $BUILDROOTFS_OUTPUT_PATH/axera-image .
# [ -f "../build_AX630C_LITE_buildroot/buildroot/output/images/rootfs.tar" ] && cp -rf ../build_AX630C_LITE_buildroot/buildroot/output/axera-image .

[ -d "ubuntu-rootfs" ] || sudo mkdir -p ubuntu-rootfs

sudo tar zxf ../$ubuntu_rootfs_path -C ubuntu-rootfs
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/opt ubuntu-rootfs/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/soc ubuntu-rootfs/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/lib/modules ubuntu-rootfs/lib -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/lib/firmware ubuntu-rootfs/firmware -a

sudo rm ubuntu-rootfs/usr/bin/sh -f
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/bin/busybox ubuntu-rootfs/usr/bin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/sbin/devmem ubuntu-rootfs/usr/sbin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/sbin/hwclock ubuntu-rootfs/usr/sbin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/bin/sh ubuntu-rootfs/usr/bin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/usr/lib/libcrypto.so.1.1 ubuntu-rootfs/usr/lib/ -a

sudo find ubuntu-rootfs -name ".empty" -exec rm {} -f \;
sudo rm axera-image/rootfs_sparse.ext4
sudo ../bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s axera-image/rootfs_sparse.ext4 ubuntu-rootfs/

cd axera-image
zip -r ../output.zip .
cd ..
mv output.zip M5_ubuntu22.04_$(date +%Y%m%d)${EXT_BOARD_NAME}.axp

image_name=`pwd`/M5_ubuntu22.04_$(date +%Y%m%d)${EXT_BOARD_NAME}.axp

# sudo rm ubuntu-rootfs -rf
sudo rm ubuntu-rootfs.bak -rf
sudo mv ubuntu-rootfs ubuntu-rootfs.bak
popd
echo "$image_name creat success!"


