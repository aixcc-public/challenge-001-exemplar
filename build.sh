#!/bin/bash

# default is: make -j$(nproc)
eval "$KERNEL_MAKE_CMD"

$CC $CFLAGS \
    $SRC/test_harnesses/linux_test_harness.c \
    -o $OUT/linux_test_harness

