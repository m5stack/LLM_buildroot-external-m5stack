#!/bin/bash
# TARGET_DIR
mkdir -p ${TARGET_DIR}/soc
mkdir -p ${TARGET_DIR}/opt
tar zxf ${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/module_LLM/image_support/soc.tar.gz -C ${TARGET_DIR}/soc
[ -f "${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/module_LLM/image_support/opt.tar.gz" ] && tar zxf ${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/module_LLM/image_support/opt.tar.gz -C ${TARGET_DIR}/opt
rm ${TARGET_DIR}/boot -rf
exit 0