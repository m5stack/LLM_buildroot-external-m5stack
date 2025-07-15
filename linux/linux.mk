# define MY_LINUX_PRE_BUILD_HOOK
# 	$(Q)cp $(BR2_EXTERNAL_M5STACK_PATH)/board/m5stack/osal_all_code.o $(LINUX_DIR)/drivers/soc/axera/osal/osal_all_code.o
# endef

# LINUX_PRE_BUILD_HOOKS += MY_LINUX_PRE_BUILD_HOOK

# LINUX_ARCH_PATH = $(LINUX_DIR)/build/linux-4.19.125/arch/arm64
BR2_BOARD_M5STACK_NAME_STR=$(subst ",,$(BR2_BOARD_M5STACK_NAME))
BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR=$(subst ",,$(BR2_LINUX_KERNEL_INTREE_DTS_NAME))

define AX630C_emmc_arm64_k419_LINUX_TARGET_FINALIZE_HOOK
	if [[ "$(BINARIES_DIR)/Image.axgzip" -ot "$(BINARIES_DIR)/Image" ]] ; then $(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/Image ;fi
	if [[ "$(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb.axgzip" -ot "$(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb" ]] ; then $(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb ;fi
	if [[ "$(BINARIES_DIR)/boot_signed.bin" -ot "$(BINARIES_DIR)/Image.axgzip" ]] ; then python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/Image.axgzip \
		-o $(BINARIES_DIR)/boot_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS) ;fi
	if [[ "$(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb" -ot "$(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb.axgzip" ]] ; then python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb.axgzip \
		-o $(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS) ;fi
	cp $(BINARIES_DIR)/boot_signed.bin $(BINARIES_DIR)/boot_signed.bin.1
	cp $(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb $(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb.1
endef

define AX650_emmc_LINUX_TARGET_FINALIZE_HOOK
	python3 $(SEC_SIGN_SCRIPT) -i $(BINARIES_DIR)/Image -pub $(PUB_KEY) -prv $(PRIV_KEY)  -o $(BINARIES_DIR)/boot_signed.bin $(SEC_SIGN_PARAMS) 
	python3 $(SEC_SIGN_SCRIPT) -i $(BINARIES_DIR)/$(BR2_LINUX_KERNEL_INTREE_DTS_NAME_STR).dtb -pub $(PUB_KEY) -prv $(PRIV_KEY) -o $(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb $(SEC_SIGN_PARAMS) 
	cp $(BINARIES_DIR)/boot_signed.bin $(BINARIES_DIR)/recovery_signed.bin
	cp $(BINARIES_DIR)/$(BR2_BOARD_M5STACK_NAME_STR)_signed.dtb $(BINARIES_DIR)/recovery_signed.dtb
endef


LINUX_TARGET_FINALIZE_HOOKS += $(BR2_BOARD_M5STACK_NAME_STR)_LINUX_TARGET_FINALIZE_HOOK
