#!/usr/bin/env bash
if [ -z "${EXT_ROOTFS_SIZE}" ]; then
    export EXT_ROOTFS_SIZE=30606884864
fi
main()
{
	work_dir="output/images"

	# BR2_EXTERNAL_M5STACK_PATH
	# OUTPUT_DIR=${OUTPUT_DIR}/..
	# BINARIES_DIR

	mkdir ${BINARIES_DIR}/rootfs
	tar xf ${BINARIES_DIR}/rootfs.tar -C ${BINARIES_DIR}/rootfs
	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/make_ext4fs -l ${EXT_ROOTFS_SIZE} -s ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/rootfs/
	rm ${BINARIES_DIR}/rootfs -rf

	mkdir -p ${BINARIES_DIR}/../axera-image
	tar zxf ${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/image_overlay.tar.gz -C ${BINARIES_DIR}/../axera-image

	cp ${BINARIES_DIR}/u-boot_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/u-boot_b_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb.1 ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/boot_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/boot_signed.bin.1 ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/fdl2_signed.bin ${BINARIES_DIR}/../axera-image
	current_date=$(date +"%Y%m%d%H%M%S")
	sed_cmd="s|V2.0.0_P7_20240513101106_20241120144606|V2.0.0_P7_20240513101106_${current_date}|g"
	sed -i "${sed_cmd}" "${BINARIES_DIR}/../axera-image/AX630C_emmc_arm64_k419.xml"

	cd ${BINARIES_DIR}/../axera-image
	zip -r ../output.zip .
	cd ..
	mv output.zip M5_LLM_buildroot_$(date +%Y%m%d).axp
	exit $?
}

main $@
