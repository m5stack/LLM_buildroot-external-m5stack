# define MY_LINUX_PRE_BUILD_HOOK
# 	$(Q)cp $(BR2_EXTERNAL_M5STACK_PATH)/board/m5stack/osal_all_code.o $(LINUX_DIR)/drivers/soc/axera/osal/osal_all_code.o
# endef

# LINUX_PRE_BUILD_HOOKS += MY_LINUX_PRE_BUILD_HOOK

# LINUX_ARCH_PATH = $(LINUX_DIR)/build/linux-4.19.125/arch/arm64


define MY_LINUX_TARGET_FINALIZE_HOOK
	$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/Image
	$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME).dtb
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/Image.axgzip \
		-o $(BINARIES_DIR)/boot_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME).dtb.axgzip \
		-o $(BINARIES_DIR)/AX630C_emmc_arm64_k419_signed.dtb -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	cp $(BINARIES_DIR)/boot_signed.bin $(BINARIES_DIR)/boot_signed.bin.1
	cp $(BINARIES_DIR)/AX630C_emmc_arm64_k419_signed.dtb $(BINARIES_DIR)/AX630C_emmc_arm64_k419_signed.dtb.1
endef
LINUX_TARGET_FINALIZE_HOOKS += MY_LINUX_TARGET_FINALIZE_HOOK