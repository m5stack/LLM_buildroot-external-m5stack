SIGN_SCRIPT=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/sec_boot_AX620E_sign.py
# PUB_KEY="$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/key_3072/pubkey.pem"
# PRIV_KEY="$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/key_3072/private.pem"
# SIGN_PARAMS="-cap 0x54FEFE -key_bit 3072"

PUB_KEY=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/public.pem
PRIV_KEY=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/private.pem
SIGN_PARAMS=-cap 0x54FAFE -key_bit 2048



SEC_SIGN_SCRIPT=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/sec_boot_AX650_sign_v2.py
SEC_SIGN_PARAMS=-cap 0x6fafe -key_bit 2048


SPL_SIGN_SCRIPT=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/spl_AX650_sign_bk.py
SPL_SIGN_PARAMS=-fw $(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/eip.bin -cap 0x4fafe -partsize 0x180000


FDL_SIGN_SCRIPT=$(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/fdl_AX650_sign.py
FDL_SIGN_PARAMS=-fw $(BR2_EXTERNAL_M5STACK_PATH)/tools/bin/imgsign/eip.bin -cap 0x4fafe -partsize 0x180000


