#! /usr/bin/bash

_cross_compile="$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
_cross_compile_32="$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
# Get the clang version from current AOSP documentation
_clang_version=$(awk '/^\* \[\*\*Android Linux Kernel/{f=NR} /^  \* Currently clang-/ && f==NR-1 {print $NF; exit}' $ANDROID_ROOT/prebuilts/clang/host/linux-x86/README.md)
_clang_path="$ANDROID_ROOT/prebuilts/clang/host/linux-x86/$_clang_version/bin"
echo "==> Using clang $_clang_path"

_defconfig=aosp_${_platform}_${_device}_defconfig

echo "==> Entering $_kernel_path"
pushd "$_kernel_path" || (echo "ERROR: Failed to cd into kernel source!"; exit 1)

echo "==> Building $_defconfig"
make $_make_vars $_defconfig

echo "==> Building $_targets with clang"
make $_make_vars CROSS_COMPILE="$_cross_compile" CROSS_COMPILE_ARM32="$_cross_compile_32" CC="${_clang_path}/clang" CLANG_TRIPLE=aarch64-linux-gnu $_targets

echo "==> $_targets compiled successfully"
popd
