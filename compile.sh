#! /usr/bin/bash

_out=$ANDROID_ROOT/out/kernel-mainline
_kernel=$_out/arch/arm64/boot/Image.gz-dtb
_kernel_path=$(realpath "$ANDROID_ROOT/kernel/mainline/kernel")

_targets=Image.gz

# if [ "$_has_dtbo" = "true" ]; then
_targets+=" dtbs"
#     _dtbo_out=$_device-dtbo.img
# fi

_make_args="O=$_out ARCH=arm64 -j$(nproc)"

_self_dir=$(realpath "$(dirname "$0")")
# Assume gcc for shellcheck, not too relevant
# shellcheck source=setup_gcc.sh
. "$_self_dir/setup_${_compiler}.sh"

_build_cmd="make $_make_args"

_defconfig=defconfig

echo "==> Entering $_kernel_path"
pushd "$_kernel_path" || (echo "ERROR: Failed to cd into kernel source!"; exit 1)

    echo "==> Building $_defconfig"
    $_build_cmd "$_defconfig"

    echo "==> Building $_targets with $_compiler"
    # _targets requires word splitting
    # shellcheck disable=SC2086
    time $_build_cmd $_targets

    echo "==> $_targets compiled successfully"
popd

cat "${_kernel%-dtb}" "$_out/arch/arm64/boot/dts/qcom/$_soc-sony-xperia-$_platform-$_device.dtb" > "$_kernel"
