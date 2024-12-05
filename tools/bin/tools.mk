SIGN_SCRIPT=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/sec_boot_AX620E_sign.py
# PUB_KEY="$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/key_3072/pubkey.pem"
# PRIV_KEY="$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/key_3072/private.pem"
# SIGN_PARAMS="-cap 0x54FEFE -key_bit 3072"

PUB_KEY=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/public.pem
PRIV_KEY=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/private.pem
SIGN_PARAMS=-cap 0x54FAFE -key_bit 2048