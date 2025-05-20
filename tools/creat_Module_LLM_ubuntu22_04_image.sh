#!/bin/bash -x
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT
export EXT_BOARD_NAME="_AX630C_LLM"
if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi

work_dir=build_Module_LLM_ubuntu22_04
ubuntu_rootfs_path="build_AX630C_LLM_ubuntu22_04_rootfs/AX630C_LLM_ubuntu22_04_rootfs.tar.gz"
BUILDROOTFS_OUTPUT_PATH="../build_Module_LLM_buildroot/buildroot/output"


./creat_Module_LLM_buildroot_image.sh
[ -f "$ubuntu_rootfs_path" ] || ./mk_AX630C_LLM_ubuntu_rootfs.sh
pushd $work_dir
[ -d "../$BUILDROOTFS_OUTPUT_PATH/axera-image" ] && cp -rf ../$BUILDROOTFS_OUTPUT_PATH/axera-image .
# [ -f "../build_AX630C_LITE_buildroot/buildroot/output/images/rootfs.tar" ] && cp -rf ../build_AX630C_LITE_buildroot/buildroot/output/axera-image .

[ -d "uboot-rootfs" ] || sudo mkdir -p uboot-rootfs

sudo tar zxf ../$ubuntu_rootfs_path -C uboot-rootfs
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/opt uboot-rootfs/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/soc uboot-rootfs/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/lib/modules uboot-rootfs/lib -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/lib/firmware uboot-rootfs/firmware -a

sudo rm uboot-rootfs/usr/bin/sh -f
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/bin/busybox uboot-rootfs/usr/bin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/sbin/devmem uboot-rootfs/usr/sbin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/sbin/hwclock uboot-rootfs/usr/sbin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/bin/sh uboot-rootfs/usr/bin/ -a
sudo cp $BUILDROOTFS_OUTPUT_PATH/target/usr/lib/libcrypto.so.1.1 uboot-rootfs/usr/lib/ -a

sudo find uboot-rootfs -name ".empty" -exec rm {} -f \;
sudo rm axera-image/rootfs_sparse.ext4
sudo ../bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s axera-image/rootfs_sparse.ext4 uboot-rootfs/

cd axera-image
zip -r ../output.zip .
cd ..
mv output.zip M5_ubuntu22.04_$(date +%Y%m%d)${EXT_BOARD_NAME}.axp

image_name=`pwd`/M5_ubuntu22.04_$(date +%Y%m%d)${EXT_BOARD_NAME}.axp

# sudo rm uboot-rootfs -rf

popd
echo "$image_name creat success!"


