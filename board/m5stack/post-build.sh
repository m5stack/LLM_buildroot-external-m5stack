#!/bin/bash
# TARGET_DIR
mkdir -p ${TARGET_DIR}/soc
tar zxf ${BR2_EXTERNAL_M5STACK_PATH}/board/m5stack/soc.tar.gz -C ${TARGET_DIR}/soc
rm ${TARGET_DIR}/boot -rf
exit 0