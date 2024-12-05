#!/usr/bin/env bash

main()
{
	work_dir="output/images"

	# BR2_EXTERNAL_M5STACK_PATH
	# OUTPUT_DIR=${OUTPUT_DIR}/..
	# BINARIES_DIR
	SIGN_SCRIPT=${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/imgsign/sec_boot_AX620E_sign.py
	# PUB_KEY="${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/imgsign/key_3072/pubkey.pem"
	# PRIV_KEY="${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/imgsign/key_3072/private.pem"
	# SIGN_PARAMS="-cap 0x54FEFE -key_bit 3072"

	PUB_KEY="${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/imgsign/public.pem"
	PRIV_KEY="${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/imgsign/private.pem"
	SIGN_PARAMS="-cap 0x54FAFE -key_bit 2048"


	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/ax_gzip -9 ${BINARIES_DIR}/u-boot-dtb.bin
	python3 ${SIGN_SCRIPT} -i ${BINARIES_DIR}/u-boot-dtb_axgzip.bin \
		-o ${BINARIES_DIR}/u-boot_signed.bin -pub ${PUB_KEY} -prv ${PRIV_KEY} ${SIGN_PARAMS}
	cp ${BINARIES_DIR}/u-boot_signed.bin ${BINARIES_DIR}/u-boot_b_signed.bin

	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/ax_gzip -9 ${BINARIES_DIR}/Image
	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/ax_gzip -9 ${BINARIES_DIR}/m5stack-ax630c-module-llm.dtb
	python3 ${SIGN_SCRIPT} -i ${BINARIES_DIR}/Image.axgzip \
		-o ${BINARIES_DIR}/boot_signed.bin -pub ${PUB_KEY} -prv ${PRIV_KEY} ${SIGN_PARAMS}
	python3 ${SIGN_SCRIPT} -i ${BINARIES_DIR}/m5stack-ax630c-module-llm.dtb.axgzip \
		-o ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb -pub ${PUB_KEY} -prv ${PRIV_KEY} ${SIGN_PARAMS}
	cp ${BINARIES_DIR}/boot_signed.bin ${BINARIES_DIR}/boot_signed.bin.1
	cp ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb ${BINARIES_DIR}/AX630C_emmc_arm64_k419_signed.dtb.1

	mkdir ${BINARIES_DIR}/rootfs
	fuse2fs ${BINARIES_DIR}/rootfs.ext2 ${BINARIES_DIR}/rootfs
	${BR2_EXTERNAL_M5STACK_PATH}/tools/bin/make_ext4fs -l 30606884864 -s ${BINARIES_DIR}/rootfs_sparse.ext4
	fusermount -u ${BINARIES_DIR}/rootfs
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
