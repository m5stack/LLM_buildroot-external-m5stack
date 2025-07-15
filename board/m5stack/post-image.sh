#!/usr/bin/env bash
# local SCRIPT_PATH=$(dirname "$0")
if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi

BR2_BOARD_M5STACK_NAME=$(grep -oP 'BR2_BOARD_M5STACK_NAME=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)
BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)
BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)

# BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY=/home/nihao/w2T/axera/LLM_buildroot-external-st/board/m5stack/ax8850_base/image_support/ax8850_v3.6.2_image_overlay.tar.gz
echo "BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY: $BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY"
if echo "$BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY" | grep -q "^http"; then
    [ -f "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256}-image_overlay.tar.gz" ] || wget --passive-ftp -nd -t 3 -O "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256}-image_overlay.tar.gz" "${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY}"
    BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY="${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256}-image_overlay.tar.gz"
    actual_sha256=$(sha256sum "$BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY" | awk '{print $1}')
    if [ "$actual_sha256" != "$BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256" ]; then
		echo "Verification failed: The SHA256 value of the file ${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY} does not match."
		echo "Expected value: $BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY_SHA256"
		echo "Actual value: $actual_sha256"
        rm ${BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY}
        exit 3
    fi
fi

main()
{
	work_dir="output/images"
	mkdir ${BINARIES_DIR}/rootfs
	tar xf ${BINARIES_DIR}/rootfs.tar -C ${BINARIES_DIR}/rootfs
	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/rootfs/
	rm ${BINARIES_DIR}/rootfs -rf

	mkdir -p ${BINARIES_DIR}/../axera-image
	tar zxf $BR2_M5STACK_BSP_SUPPORT_IMAGE_OVERLAY -C ${BINARIES_DIR}/../axera-image


	if [ -f "${BINARIES_DIR}/../axera-image/update.sh" ] ; then 
		${BINARIES_DIR}/../axera-image/update.sh
		rm -rf ${BINARIES_DIR}/../axera-image/update.sh
	else
		cp ${BINARIES_DIR}/u-boot_signed.bin ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/u-boot_b_signed.bin ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/${BR2_BOARD_M5STACK_NAME}_signed.dtb ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/${BR2_BOARD_M5STACK_NAME}_signed.dtb.1 ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/boot_signed.bin ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/boot_signed.bin.1 ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/../axera-image
		cp ${BINARIES_DIR}/fdl2_signed.bin ${BINARIES_DIR}/../axera-image
	fi
	cd ${BINARIES_DIR}/../axera-image
	zip -r ../output.zip .
	cd ..
	mv output.zip M5_${BR2_BOARD_M5STACK_NAME}_buildroot_$(date +%Y%m%d)${EXT_BOARD_NAME}.axp
	exit $?
}

main $@
