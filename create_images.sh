#! /usr/bin/bash

# See PLATFORM_SECURITY_PATCH in $ANDROID_ROOT/build/make/core/version_defaults.mk

if _os_patch_level=$(grep -Po 'PLATFORM_SECURITY_PATCH\s+:=\s+\K([0-9]{4}(-[0-9]{2}){2})' "$ANDROID_ROOT/build/make/core/version_defaults.mk"); then
    echo "Using SPL $_os_patch_level from Android tree"
else
    _os_patch_level='2020-06-05'
    echo "WARNING: Patch level not found in Android tree. Using $_os_patch_level"
fi

_os_version=10

echo "==> Generating images for patch level $_os_patch_level"

# mkdir -p $(dirname $_boot_out)

if [[ "$_has_dtbo" == "true" ]]; then
    _dts_folder="$_out/arch/arm64/boot/dts/qcom"
    _files=$(find "$_dts_folder" -iname "*.dtbo")
    echo "==> Creating dtboimg from $_files"
    "$_kernel_path/scripts/mkdtboimg.py" create "$_device-dtbo.img" --page_size="$BOARD_KERNEL_PAGESIZE" $_files
fi

if [[ "$_permissive" == "true" ]]; then
    echo "==> Adding permissive to cmdline"
    BOARD_KERNEL_CMDLINE+=" androidboot.selinux=permissive"
    #  enforcing=0 selinux=0
fi
# TODO MOVE IT ALL HERE
# BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
#BOARD_KERNEL_CMDLINE+=" console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0"
BOARD_KERNEL_CMDLINE+=" androidboot.memcg=1"
BOARD_KERNEL_CMDLINE+=" msm_rtb.filter=0x3F ehci-hcd.park=3"
BOARD_KERNEL_CMDLINE+=" coherent_pool=8M"
BOARD_KERNEL_CMDLINE+=" sched_enable_power_aware=1 user_debug=31"
BOARD_KERNEL_CMDLINE+=" printk.devkmsg=on"
BOARD_KERNEL_CMDLINE+=" loop.max_part=16"
BOARD_KERNEL_CMDLINE+=" kpti=0"

echo "$BOARD_KERNEL_CMDLINE"


echo "==> Creating $_boot_out..."

$ANDROID_ROOT/out/host/linux-x86/bin/mkbootimg --kernel "$_kernel" --ramdisk "$_ramdisk" --cmdline "$BOARD_KERNEL_CMDLINE" --base "$BOARD_KERNEL_BASE" --pagesize "$BOARD_KERNEL_PAGESIZE" --os_version "$_os_version" --os_patch_level "$_os_patch_level" --ramdisk_offset "$BOARD_RAMDISK_OFFSET" --tags_offset "$BOARD_KERNEL_TAGS_OFFSET" --output "$_boot_out" --id

echo "==> mkbootimg successful, created $_boot_out"
