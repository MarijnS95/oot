#! /usr/bin/bash

_cross_compile="/data/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
# TODO: Cannot use gcc 4.9 since 4.14.218: https://github.com/sonyxperiadev/kernel/blame/409132320fe5e08d558e979ce92f39208e885010/include/linux/compiler-gcc.h#L155-L160
_cross_compile_32="$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

_make_args+=" CROSS_COMPILE=$_cross_compile CROSS_COMPILE_ARM32=$_cross_compile_32"
