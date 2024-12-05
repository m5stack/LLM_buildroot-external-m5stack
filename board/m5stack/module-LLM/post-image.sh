#!/usr/bin/env bash

main()
{
	work_dir="output/images"

	# BR2_EXTERNAL_M5STACK_PATH
	# OUTPUT_DIR=${OUTPUT_DIR}/..
	# BINARIES_DIR

	mkdir ${BINARIES_DIR}/rootfs
	tar xf ${BINARIES_DIR}/rootfs.tar -C ${BINARIES_DIR}/rootfs
	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/make_ext4fs -l 30606884864 -s ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/rootfs/
	rm ${BINARIES_DIR}/rootfs -rf

	mkdir -p ${BINARIES_DIR}/../axera-image
	tar zxvf ${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/module-LLM/image_overlay.tar.gz -C ${BINARIES_DIR}/../axera-image

	cp ${BINARIES_DIR}/u-boot_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/u-boot_b_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb.1 ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/boot_signed.bin ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/boot_signed.bin.1 ${BINARIES_DIR}/../axera-image
	cp ${BINARIES_DIR}/rootfs_sparse.ext4 ${BINARIES_DIR}/../axera-image

	cd ${BINARIES_DIR}/../axera-image
	zip -r ../output.zip .
	cd ..
	mv output.zip M5_LLM_buildroot_$(date +%Y%m%d).axp
	exit $?
}

main $@
