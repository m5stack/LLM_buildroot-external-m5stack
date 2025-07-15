#define MY_UBOOT_PRE_BUILD_HOOK
#	$(Q)cp $(BR2_EXTERNAL_M5STACK_PATH)/board/m5stack/module-LLM/pinmux/* $(UBOOT_DIR)/board/axera/ax620e_emmc/
#endef
#UBOOT_PRE_BUILD_HOOKS += MY_UBOOT_PRE_BUILD_HOOK
BR2_BOARD_M5STACK_NAME_STR=$(subst ",,$(BR2_BOARD_M5STACK_NAME))

define AX630C_emmc_arm64_k419_UBOOT_POST_INSTALL_IMAGES_HOOK
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb.bin \
		-o $(BINARIES_DIR)/fdl2_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/u-boot-dtb.bin
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb_axgzip.bin \
		-o $(BINARIES_DIR)/u-boot_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	cp $(BINARIES_DIR)/u-boot_signed.bin $(BINARIES_DIR)/u-boot_b_signed.bin
endef


define AX650_emmc_UBOOT_POST_INSTALL_IMAGES_HOOK
	python3 $(SPL_SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb.bin \
		-o $(BINARIES_DIR)/u-boot_signed.bin -ob $(BINARIES_DIR)/uboot_bk.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SPL_SIGN_PARAMS)
	python3 $(FDL_SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb.bin \
		-o $(BINARIES_DIR)/fdl2_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(FDL_SIGN_PARAMS)
endef


UBOOT_POST_INSTALL_IMAGES_HOOKS += $(BR2_BOARD_M5STACK_NAME_STR)_UBOOT_POST_INSTALL_IMAGES_HOOK

UBOOT_MAKE_TARGET := $(filter-out all,$(UBOOT_MAKE_TARGET))

