#!/bin/bash
# TARGET_DIR
# local SCRIPT_PATH=$(dirname "$0")

BR2_M5STACK_BSP_SUPPORT_OPT=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_OPT=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)
BR2_M5STACK_BSP_SUPPORT_SOC=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_SOC=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)
BR2_M5STACK_BSP_SUPPORT_OPT_SHA256=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_OPT_SHA256=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)
BR2_M5STACK_BSP_SUPPORT_SOC_SHA256=$(grep -oP 'BR2_M5STACK_BSP_SUPPORT_SOC_SHA256=\K(y|".*?"|\d+)' $BR2_CONFIG | cut -d '"' -f 2)

if echo "$BR2_M5STACK_BSP_SUPPORT_OPT" | grep -q "^http"; then
    [ -f "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_OPT_SHA256}-opt.tar.gz" ] || wget --passive-ftp -nd -t 3 -O "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_OPT_SHA256}-opt.tar.gz" "${BR2_M5STACK_BSP_SUPPORT_OPT}"
    BR2_M5STACK_BSP_SUPPORT_OPT="${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_OPT_SHA256}-opt.tar.gz"
    actual_sha256=$(sha256sum "$BR2_M5STACK_BSP_SUPPORT_OPT" | awk '{print $1}')
    if [ "$actual_sha256" != "$BR2_M5STACK_BSP_SUPPORT_OPT_SHA256" ]; then
        echo "Verification failed: The SHA256 value of the file ${BR2_M5STACK_BSP_SUPPORT_OPT} does not match."
        echo "Expected value: $BR2_M5STACK_BSP_SUPPORT_OPT_SHA256"
        echo "Actual value: $actual_sha256"
        rm ${BR2_M5STACK_BSP_SUPPORT_OPT}
        exit 3
    fi
fi
if echo "$BR2_M5STACK_BSP_SUPPORT_SOC" | grep -q "^http"; then
    [ -f "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_SOC_SHA256}-soc.tar.gz" ] || wget --passive-ftp -nd -t 3 -O "${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_SOC_SHA256}-soc.tar.gz" "${BR2_M5STACK_BSP_SUPPORT_SOC}"
    BR2_M5STACK_BSP_SUPPORT_SOC="${BR2_DL_DIR}/${BR2_M5STACK_BSP_SUPPORT_SOC_SHA256}-soc.tar.gz"
    actual_sha256=$(sha256sum "$BR2_M5STACK_BSP_SUPPORT_SOC" | awk '{print $1}')
    if [ "$actual_sha256" != "$BR2_M5STACK_BSP_SUPPORT_SOC_SHA256" ]; then
        echo "Verification failed: The SHA256 value of the file ${BR2_M5STACK_BSP_SUPPORT_SOC} does not match."
        echo "Expected value: $BR2_M5STACK_BSP_SUPPORT_SOC_SHA256"
        echo "Actual value: $actual_sha256"
        rm ${BR2_M5STACK_BSP_SUPPORT_SOC}
        exit 3
    fi
fi


mkdir -p ${TARGET_DIR}/soc
mkdir -p ${TARGET_DIR}/opt
[ -f "$BR2_M5STACK_BSP_SUPPORT_SOC" ] && tar zxf $BR2_M5STACK_BSP_SUPPORT_SOC -C ${TARGET_DIR}/soc
[ -f "$BR2_M5STACK_BSP_SUPPORT_OPT" ] && tar zxf $BR2_M5STACK_BSP_SUPPORT_OPT -C ${TARGET_DIR}/opt


rm ${TARGET_DIR}/boot -rf
exit 0