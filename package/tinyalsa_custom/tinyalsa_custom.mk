################################################################################
#
# tinyalsa_custom
#
################################################################################

TINYALSA_CUSTOM_VERSION = 2.0.0

TINYALSA_CUSTOM_TARBALL = $(call qstrip,$(call github,tinyalsa,tinyalsa,v$(TINYALSA_CUSTOM_VERSION))/tinyalsa-$(TINYALSA_CUSTOM_VERSION).tar.gz)
TINYALSA_CUSTOM_SITE = $(patsubst %/,%,$(dir $(TINYALSA_CUSTOM_TARBALL)))
TINYALSA_CUSTOM_SOURCE = $(notdir $(TINYALSA_CUSTOM_TARBALL))

TINYALSA_CUSTOM_LICENSE = BSD-3-Clause
TINYALSA_CUSTOM_LICENSE_FILES = NOTICE
TINYALSA_CUSTOM_INSTALL_STAGING = YES
TINYALSA_CUSTOM_CONF_OPTS = -Ddocs=disabled -Dexamples=disabled

$(eval $(meson-package))