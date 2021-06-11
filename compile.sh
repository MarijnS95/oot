#! /usr/bin/bash

if [ "$_separate_kernel_dir" == "true" ]; then
    # One kernel tmp/out dir per device
    _out=$ANDROID_ROOT/out/kernel-$_kernel_major.$_kernel_minor/$_compiler/$_device
else
    # Share kernel tmp/out across devices of each platform
    _out=$ANDROID_ROOT/out/kernel-$_kernel_major.$_kernel_minor/$_compiler/$_platform
fi
_kernel=$_out/arch/arm64/boot/Image.gz-dtb
_kernel_path="$ANDROID_ROOT/kernel/sony/msm-$_kernel_major.$_kernel_minor/kernel"

_targets=Image.gz-dtb

if [ "$_has_dtbo" = "true" ]; then
    _targets="$_targets dtbs"
    _dtbo_out=$_device-dtbo.img
fi

_make_args="O=$_out ARCH=arm64 -j$(nproc)"

_self_dir=$(realpath $(dirname "$0"))
. $_self_dir/setup_$_compiler.sh

_build_cmd="make $_make_args"

_defconfig=aosp_${_platform}_${_device}_defconfig

echo "==> Entering $_kernel_path"
pushd "$_kernel_path" || (echo "ERROR: Failed to cd into kernel source!"; exit 1)

    echo "==> Building $_defconfig"
    $_build_cmd $_defconfig

    echo "==> Building $_targets with $_compiler"
    time $_build_cmd $_targets

    echo "==> $_targets compiled successfully"
popd
