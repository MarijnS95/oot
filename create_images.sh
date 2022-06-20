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

# True by default, analogous to BOARD_USES_RECOVERY_AS_BOOT:
[ "$_recovery_ramdisk" = "false" ] && _ramdisk=ramdisk.img || _ramdisk=ramdisk-recovery.img
_ramdisk=$ANDROID_ROOT/out/target/product/$_device/$_ramdisk

[ ! -f "$_ramdisk" ] && echo "WARNING: $_ramdisk does not exist!"

# mkdir -p $(dirname $_boot_out)

if [[ "$_has_dtbo" == "true" ]]; then
    echo "==> Creating empty dtboimg"
    _dtbo_out=empty_dtbo.img
    dd if=/dev/zero of="$_dtbo_out" count=2

    # _dts_folder="$_out/arch/arm64/boot/dts"
    # _files=$(find "$_dts_folder" -iname "*.dtbo")
    # echo "==> Creating dtboimg from $_files"
    # _mkdtboimg="$_kernel_path/scripts/mkdtboimg.py"
    # [[ ! -f "$_mkdtboimg" ]] && _mkdtboimg="$ANDROID_ROOT/prebuilts/misc/linux-x86/libufdt/mkdtimg"
    # [[ ! -f "$_mkdtboimg" ]] && _mkdtboimg="$ANDROID_ROOT/system/libufdt/utils/src/mkdtboimg.py"
    # [[ ! -f "$_mkdtboimg" ]] && (echo "No mkdtbo script/executable found"; exit 1)
    # echo "==> Using mkdtbo at $_mkdtboimg"
    # # --page_size="$BOARD_KERNEL_PAGESIZE"
    # # _files requires word splitting (Tama has multiple dtbo files)
    # # shellcheck disable=SC2086
    # "$_mkdtboimg" create "$_device-dtbo.img" $_files
fi

if [[ "$_has_vendor_boot" == "true" ]]; then
    echo "TODO: Create and flash vendor_boot"; exit 1
fi

if [[ "${_permissive:-false}" == "true" ]]; then
    echo "==> Adding permissive to cmdline"
    BOARD_KERNEL_CMDLINE+=" androidboot.selinux=permissive"
    #  enforcing=0 selinux=0
fi

# TODO MOVE IT ALL HERE
# BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
#BOARD_KERNEL_CMDLINE+=" console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0"
BOARD_KERNEL_CMDLINE+=" androidboot.memcg=1"
# BOARD_KERNEL_CMDLINE+=" msm_rtb.filter=0x3F ehci-hcd.park=3"
# BOARD_KERNEL_CMDLINE+=" coherent_pool=8M"
#BOARD_KERNEL_CMDLINE+=" sched_enable_power_aware=1 user_debug=31"
BOARD_KERNEL_CMDLINE+=" printk.devkmsg=on"
#BOARD_KERNEL_CMDLINE+=" loglevel=8 debug"
# BOARD_KERNEL_CMDLINE+=" loop.max_part=16"
# BOARD_KERNEL_CMDLINE+=" kpti=0"

BOARD_KERNEL_CMDLINE+=" deferred_probe_timeout=4"

echo "$BOARD_KERNEL_CMDLINE"


echo "==> Creating $_boot_out..."
echo "==> Using $_ramdisk"

"$ANDROID_ROOT/out/host/linux-x86/bin/mkbootimg" \
    --kernel "$_kernel" \
    --ramdisk "$_ramdisk" \
    --cmdline "$BOARD_KERNEL_CMDLINE" \
    --base "$BOARD_KERNEL_BASE" \
    --pagesize "$BOARD_KERNEL_PAGESIZE" \
    --os_version "$_os_version" \
    --os_patch_level "$_os_patch_level" \
    --ramdisk_offset "$BOARD_RAMDISK_OFFSET" \
    --tags_offset "$BOARD_KERNEL_TAGS_OFFSET" \
    "${_mkbootimg_args[@]}" \
    --output "$_boot_out" \
    --id

echo "==> mkbootimg successful, created $_boot_out"
