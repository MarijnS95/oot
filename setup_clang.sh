#! /usr/bin/bash

_cross_compile="$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
# Get the clang version from current AOSP documentation
_clang_version=$(awk '/^\* \[\*\*Android Linux Kernel/{f=NR} /^  \* Currently clang-/ && f==NR-1 {print $NF; exit}' "$ANDROID_ROOT/prebuilts/clang/host/linux-x86/README.md")
_clang_path="$ANDROID_ROOT/prebuilts/clang/host/linux-x86/$_clang_version/bin"

_make_args+=" CROSS_COMPILE=$_cross_compile CC=${_clang_path}/clang CLANG_TRIPLE=aarch64-linux-gnu"
