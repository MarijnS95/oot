#! /usr/bin/bash

set -e


_kernel_major=4
_kernel_minor=14

if [ -z "$ANDROID_BUILD_TOP" ]; then
    ANDROID_ROOT=$(realpath "$_self_dir/../")
    echo "WARNING: ANDROID_BUILD_TOP not set, guessing root at $ANDROID_ROOT"
else
    ANDROID_ROOT=$(realpath "$ANDROID_BUILD_TOP")
fi

_out=$ANDROID_ROOT/out/kernel-$_kernel_major$_kernel_minor/$_compiler/$_device
_kernel=$_out/arch/arm64/boot/Image.gz-dtb
_kernel_path="$ANDROID_ROOT/kernel/sony/msm-$_kernel_major.$_kernel_minor/kernel"
# True by default:
if [ "$_recovery_ramdisk" = "false" ]; then
    _ramdisk=$ANDROID_ROOT/out/target/product/$_device/ramdisk.img
else
    _ramdisk=$ANDROID_ROOT/out/target/product/$_device/ramdisk-recovery.img
fi
_boot_out=$_device-boot.img

if [ ! -f $_ramdisk ]; then
    echo "WARNING: $_ramdisk does not exist!"
fi

_targets=Image.gz-dtb

if [ "$_has_dtbo" = "true" ]; then
    _targets="$_targets dtbs"
    _dtbo_out=$_device-dtbo.img
fi

_make_args="O=$_out ARCH=arm64 -j$(nproc)"

_self_dir=$(realpath $(dirname "$0"))
. $_self_dir/setup_$_compiler.sh

_cross_compile_32="$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
_make_args+=" CROSS_COMPILE_ARM32=$_cross_compile_32"

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

. $_self_dir/create_images.sh

if [ "$_fastboot_flash" = "true" ]; then
    echo "==> Flashing $_boot_out"
    fastboot flash boot $_boot_out
    if [ "$_has_dtbo" = "true" ]; then
        echo "==> Flashing $_dtbo_out"
        fastboot flash dtbo $_dtbo_out
    fi

    echo "==> Rebooting device..."
    fastboot continue || fastboot reboot
fi
