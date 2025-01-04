#define MY_UBOOT_PRE_BUILD_HOOK
#	$(Q)cp $(BR2_EXTERNAL_M5STACK_PATH)/board/m5stack/module-LLM/pinmux/* $(UBOOT_DIR)/board/axera/ax620e_emmc/
#endef
#UBOOT_PRE_BUILD_HOOKS += MY_UBOOT_PRE_BUILD_HOOK


define MY_UBOOT_POST_INSTALL_IMAGES_HOOK
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb.bin \
		-o $(BINARIES_DIR)/fdl2_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/ax_gzip -9 $(BINARIES_DIR)/u-boot-dtb.bin
	python3 $(SIGN_SCRIPT) -i $(BINARIES_DIR)/u-boot-dtb_axgzip.bin \
		-o $(BINARIES_DIR)/u-boot_signed.bin -pub $(PUB_KEY) -prv $(PRIV_KEY) $(SIGN_PARAMS)
	cp $(BINARIES_DIR)/u-boot_signed.bin $(BINARIES_DIR)/u-boot_b_signed.bin
endef
UBOOT_POST_INSTALL_IMAGES_HOOKS += MY_UBOOT_POST_INSTALL_IMAGES_HOOK

UBOOT_MAKE_TARGET := $(filter-out all,$(UBOOT_MAKE_TARGET))

