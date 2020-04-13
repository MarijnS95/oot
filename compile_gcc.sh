#! /usr/bin/bash

_cross_compile=$(realpath "$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-")

_defconfig=aosp_${_platform}_${_device}_defconfig

echo "==> Entering $_kernel_path"
pushd "$_kernel_path" || (echo "ERROR: Failed to cd into kernel source!"; exit 1)

echo "==> Building $_defconfig"
make $_make_vars $_defconfig

echo "==> Building $_targets with AOSP gcc"
make $_make_vars CROSS_COMPILE="$_cross_compile" $_targets

echo "==> $_targets compiled successfully"
popd
