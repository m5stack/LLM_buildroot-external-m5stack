#!/bin/sh

if [ -z "$PATH" ]; then
    export PATH="/usr/local/m5stack/bin"
else
    echo "$PATH" | grep -q "/usr/local/m5stack/bin"
    if [ $? -ne 0 ]; then
        export PATH="/usr/local/m5stack/bin:$PATH"
    fi
fi
if [ -z "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH="/usr/local/m5stack/lib"
else
    echo "$LD_LIBRARY_PATH" | grep -q "/usr/local/m5stack/lib"
    if [ $? -ne 0 ]; then
        export LD_LIBRARY_PATH="/usr/local/m5stack/lib:$LD_LIBRARY_PATH"
    fi
fi


