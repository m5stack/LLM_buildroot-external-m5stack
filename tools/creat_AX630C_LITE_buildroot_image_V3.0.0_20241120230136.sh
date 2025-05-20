#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT

export EXT_BOARD_NAME="_AX630C_LITE"
clone_buildroot() {
    if [ -d '../buildroot' ] ; then
        [ -d 'buildroot' ] || cp -r ../buildroot buildroot
    else
        [ -d 'buildroot' ] || git clone https://github.com/bootlin/buildroot.git -b st/2023.02.10
    fi
    [ -d 'buildroot' ] || { echo "not found buildroot" && exit -1; }
    pushd buildroot
    hostname=$(hostname)
    if [ "$hostname" = "nihao-z690" ]; then
        [ -f 'dl.7z' ] || wget https://m5stack.oss-cn-shenzhen.aliyuncs.com/resource/linux/llm/dl.7z
        [ -d 'dl' ] || 7z x dl.7z -odl
        [ -d 'dl' ] || { echo "not found dl" && exit -1; }
    fi
    popd
}

make_buildroot() {
    cd buildroot
    make BR2_EXTERNAL=../../.. m5stack_ax630c_lite_4_19_V3_0_0_20241120230136_defconfig
    [[ -v ROOTFS_SIZE ]] && sed -i 's/^\(BR2_TARGET_ROOTFS_EXT2_SIZE=\).*$/\1"'"${ROOTFS_SIZE}"'"/' .config
    make -j `nproc`
}

sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git cmake p7zip-full python3 python3-pip expect libssl-dev qemu-user-static android-sdk-libsparse-utils -y

fun_lists=("clone_buildroot" "make_buildroot")

[ -d 'build_AX630C_LITE_buildroot_V3.0.0_20241120230136' ] || mkdir build_AX630C_LITE_buildroot_V3.0.0_20241120230136
pushd build_AX630C_LITE_buildroot_V3.0.0_20241120230136
for item in "${fun_lists[@]}"; do
    $item
    ret=$?
    [ "$ret" == "0" ] || exit $ret
done
popd

