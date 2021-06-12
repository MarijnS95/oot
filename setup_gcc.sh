#! /usr/bin/bash

# Use gcc available on PATH. On archlinux, `pacman -S aarch64-linux-gnu-gcc arm-none-eabi-gcc`

_make_args+=" CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-none-eabi-"
