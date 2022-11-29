#! /usr/bin/bash

_cross_compile="$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
# Get the clang version from current AOSP documentation
_clang_version=$(awk '/^\* \[\*\*Android Linux Kernel/{f=NR} /^  \* Currently clang-/ && f==NR-1 {print $NF; exit}' "$ANDROID_ROOT/prebuilts/clang/host/linux-x86/README.md")
_clang_path="$ANDROID_ROOT/prebuilts/clang/host/linux-x86/$_clang_version/bin"

# TODO: Cannot use gcc 4.9 since 4.14.218: https://github.com/sonyxperiadev/kernel/blame/409132320fe5e08d558e979ce92f39208e885010/include/linux/compiler-gcc.h#L155-L160
_cross_compile_32="$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

#_make_args+=" CROSS_COMPILE=$_cross_compile CC=${_clang_path}/clang CLANG_TRIPLE=aarch64-linux-gnu CROSS_COMPILE_ARM32=$_cross_compile_32"
_make_args+=" LLVM=1"
