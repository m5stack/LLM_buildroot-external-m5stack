#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BR2_EXTERNAL=$(realpath $SCRIPT_DIR/..)

export BR2_EXTERNAL
