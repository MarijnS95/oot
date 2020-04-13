#! /usr/bin/bash

_cross_compile=$(realpath "$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-")
_clang_path=$(realpath "$ANDROID_ROOT/prebuilts/clang/host/linux-x86/clang-4691093/bin/")

_defconfig=aosp_${_platform}_${_device}_defconfig

echo "==> Entering $_kernel_path"
pushd "$_kernel_path" || (echo "ERROR: Failed to cd into kernel source!"; exit 1)

echo "==> Building $_defconfig"
make $_make_vars $_defconfig

echo "==> Building $_targets with clang"
make $_make_vars CROSS_COMPILE="$_cross_compile" CC="${_clang_path}/clang" CLANG_TRIPLE=aarch64-linux-gnu $_targets

echo "==> $_targets compiled successfully"
popd
