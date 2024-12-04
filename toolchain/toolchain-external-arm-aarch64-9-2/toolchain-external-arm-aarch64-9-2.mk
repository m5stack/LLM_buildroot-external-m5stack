################################################################################
#
# toolchain-external-arm-aarch64-9-2
#
################################################################################

TOOLCHAIN_EXTERNAL_ARM_AARCH64_9_2_VERSION = 2019.12
TOOLCHAIN_EXTERNAL_ARM_AARCH64_9_2_SITE = https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-$(TOOLCHAIN_EXTERNAL_ARM_AARCH64_9_2_VERSION)/binrel
TOOLCHAIN_EXTERNAL_ARM_AARCH64_9_2_SOURCE = gcc-arm-9.2-$(TOOLCHAIN_EXTERNAL_ARM_AARCH64_9_2_VERSION)-x86_64-aarch64-none-linux-gnu.tar.xz

$(eval $(toolchain-external-package))
