#!/bin/bash
# SPDX-FileCopyrightText: 2024 M5Stack Technology CO LTD
#
# SPDX-License-Identifier: MIT



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
        [ -f '../../../board/m5stack/opt.tar.gz' ] || wget https://github.com/m5stack/LLM_buildroot-external-m5stack/releases/download/v0.0.0/opt.tar.gz -O ../../../board/m5stack/opt.tar.gz
        popd
}

make_buildroot() {
    cd buildroot
    make BR2_EXTERNAL=../../.. m5stack_module_llm_4_19_defconfig
    [[ -v ROOTFS_SIZE ]] && sed -i 's/^\(BR2_TARGET_ROOTFS_EXT2_SIZE=\).*$/\1"'"${ROOTFS_SIZE}"'"/' .config
    make -j `nproc`
}

sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git cmake p7zip-full python3 python3-pip expect libssl-dev qemu-user-static android-sdk-libsparse-utils -y

fun_lists=("clone_buildroot" "make_buildroot")

[ -d 'build_Module_LLM_buidlroot' ] || mkdir build_Module_LLM_buidlroot
pushd build_Module_LLM_buidlroot
for item in "${fun_lists[@]}"; do
    $item
    ret=$?
    [ "$ret" == "0" ] || exit $ret
done
popd

