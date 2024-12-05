#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT



clone_buildroot() {
    [ -d 'buildroot' ] || git clone https://github.com/bootlin/buildroot.git -b st/2023.02.10
    [ -d 'buildroot' ] || { echo "not found buildroot" && exit -1; }
    pushd buildroot
    # [ -f 'dl.7z' ] || wget https://github.com/m5stack/CoreMP135_buildroot/releases/download/v1.0.1/dl.7z
    # [ -d 'dl' ] || 7z x dl.7z -odl
    # [ -d 'dl' ] || { echo "not found dl" && exit -1; }
    popd
}

make_buildroot() {
    cd buildroot
    make BR2_EXTERNAL=../../.. m5stack_module_llm_4_19_defconfig
    [[ -v ROOTFS_SIZE ]] && sed -i 's/^\(BR2_TARGET_ROOTFS_EXT2_SIZE=\).*$/\1"'"${ROOTFS_SIZE}"'"/' .config
    make -j `nproc`
}

sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git cmake p7zip-full python3 python3-pip expect libssl-dev qemu-user-static fuse2fs -y

fun_lists=("clone_buildroot" "make_buildroot")

[ -d 'build_Module_LLM_buidlroot' ] || mkdir build_Module_LLM_buidlroot
pushd build_Module_LLM_buidlroot
for item in "${fun_lists[@]}"; do
    $item
    ret=$?
    [ "$ret" == "0" ] || exit $ret
done
popd

