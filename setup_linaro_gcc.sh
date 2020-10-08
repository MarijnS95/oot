#! /usr/bin/bash

_cross_compile="/data/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
_cross_compile="/data/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
_cross_compile_32="$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

_make_args+=" CROSS_COMPILE=$_cross_compile CROSS_COMPILE_ARM32=$_cross_compile_32"
