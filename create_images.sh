#! /usr/bin/bash

# See PLATFORM_SECURITY_PATCH in build/make/core/version_defaults.mk
_os_patch_level='2019-12-05'
_os_version=10

echo "==> Generating images for patch level $_os_patch_level"

# mkdir -p $(dirname $_boot_out)

if [ "$_has_dtbo" = "true" ]; then
    _dts_folder=$(realpath $_out/arch/arm64/boot/dts/qcom)
    _files=$(find $_dts_folder -iname "*.dtbo")
    echo "==> Creating dtboimg from $_files"
    python2 $_kernel_path/scripts/mkdtboimg.py create $_device-dtbo.img --page_size=$BOARD_KERNEL_PAGESIZE $_files
fi

if [ "$_permissive" = "true" ]; then
    echo "==> Adding permissive to cmdline"
    BOARD_KERNEL_CMDLINE="androidboot.selinux=permissive $BOARD_KERNEL_CMDLINE"
fi

echo "==> Creating $_boot_out..."

mkbootimg --kernel $_kernel --ramdisk $_ramdisk --cmdline "$BOARD_KERNEL_CMDLINE" --base $BOARD_KERNEL_BASE --pagesize $BOARD_KERNEL_PAGESIZE --os_version $_os_version --os_patch_level $_os_patch_level --ramdisk_offset $BOARD_RAMDISK_OFFSET --tags_offset $BOARD_KERNEL_TAGS_OFFSET --output $_boot_out --id

echo "==> mkbootimg successful, created $_boot_out"
