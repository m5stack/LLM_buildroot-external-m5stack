include $(sort $(wildcard $(BR2_EXTERNAL_M5STACK_PATH)/package/*/*.mk))
include $(sort $(wildcard $(BR2_EXTERNAL_M5STACK_PATH)/toolchain/*/*.mk))
include $(sort $(wildcard $(BR2_EXTERNAL_M5STACK_PATH)/linux/linux.mk))