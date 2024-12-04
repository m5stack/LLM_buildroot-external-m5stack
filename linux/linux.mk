define MY_LINUX_PRE_BUILD_HOOK
	$(Q)cp $(BR2_EXTERNAL_M5STACK_PATH)/board/m5stack/module-LLM/osal_all_code.o $(LINUX_DIR)/drivers/soc/axera/osal/osal_all_code.o
endef

LINUX_PRE_BUILD_HOOKS += MY_LINUX_PRE_BUILD_HOOK