#!/usr/bin/bash

set -e

_self_dir=$(dirname "${BASH_SOURCE[0]}")

if [ -z "$ANDROID_BUILD_TOP" ]; then
    ANDROID_ROOT=$(realpath "$_self_dir/../")
    echo "WARNING: ANDROID_BUILD_TOP not set, guessing root at $ANDROID_ROOT"
else
    ANDROID_ROOT=$(realpath "$ANDROID_BUILD_TOP")
fi


function usage {
    echo 'USAGE:'
    echo -e "\t$0 [FLAGS] <device> [<device>...]\t(Example for akatsuki: $0 akatsuki)"
    echo
    echo 'FLAGS:'
    echo -e '\t-c <compiler>          Select a compiler to use.'
    echo -e '\t                       Currently supported compilers are gcc, linaro_gcc and clang (defaults to clang).'
    echo -e '\t-f                     Flash the kernel after compiling (using fastboot).'
    echo -e '\t-h, --help             Show the usage of the tool'
}


while getopts 'c:fh-:' OPT; do
    case ${OPT} in
    -)
        case ${OPTARG} in
        help)
            usage
            exit
            ;;
        *)
            echo "$0: illegal option -- ${OPTARG}"
            echo && usage
            exit 1
            ;;
        esac
        ;;
    c)
        if [[ -f "$_self_dir/setup_$OPTARG.sh" ]]; then
            _compiler=${OPTARG}
        else
            echo "Compiler '${OPTARG}' unknown or not implemented"
            exit 1
        fi
        ;;
    f)
        _fastboot_flash=true
        ;;
    h)
        usage
        exit
        ;;
    *)
        echo && usage
        exit 1
        ;;
    esac
done

shift $(( OPTIND - 1 ))

if (( "$#" == 0 )); then
    usage
    exit 1
fi

# Default to clang
if [[ -z "${_compiler}" ]]; then
    _compiler=clang
fi


# Platform common
BOARD_KERNEL_BASE=0x00000000
BOARD_KERNEL_PAGESIZE=4096
BOARD_KERNEL_TAGS_OFFSET=0x01E00000
BOARD_RAMDISK_OFFSET=0x02000000

for _device in "$@"; do
    unset BOARD_KERNEL_CMDLINE _platform _has_dtbo _recovery_ramdisk _verity_file _verity_key_id

    # BOARD_KERNEL_CMDLINE+=" lpm_levels.sleep_disabled=1"
    # BOARD_KERNEL_CMDLINE+=" service_locator.enable=1"
    BOARD_KERNEL_CMDLINE+=" androidboot.hardware=${_device}"
    BOARD_KERNEL_CMDLINE+=" clk_ignore_unused pd_ignore_unused"
    BOARD_KERNEL_CMDLINE+=" PMOS_NO_OUTPUT_REDIRECT"
    BOARD_KERNEL_CMDLINE+=" log_buf_len=8M"

    # Device specific
    case ${_device} in
    suzu|kugo)
        _soc=msm8956
        _platform=loire
        ;;
    lilac|maple|poplar)
        _soc=msm8998
        _platform=yoshino
        ;;
    discovery|pioneer|voyager)
        _soc=sdm630
        _platform=nile
        ;;
    akari|akatsuki|apollo)
        _soc=sdm845
        _platform=tama
        ;;
    kirin)
        _soc=sdm630
        _platform=ganges
        ;;
    mermaid)
        _soc=sdm636
        _platform=ganges
        ;;
    bahamut|griffin)
        _soc=sm8150
        _platform=kumano
        ;;
    pdx201)
        _soc=sm6125
        _platform=seine
        ;;
    pdx20[36])
        _soc=sm8250
        _platform=edo
        ;;
    pdx213)
        _soc=sm6350
        _platform=lena
        ;;
    pdx21[45])
        _soc=sm8350
        _platform=sagami
        _kernel_major=5
        _kernel_minor=4
        ;;
    pdx22[34])
        _soc=sm8450
        _platform=nagara
        _kernel_major=5
        _kernel_minor=10
        ;;
    pdx225)
        _soc=sm6375
        _platform=murray
        _kernel_major=5
        _kernel_minor=4
        ;;
    *)
        echo "Device '${_device}' unknown or not implemented"
        exit 1
        ;;
    esac

    # Verity
    case ${_platform} in
    yoshino|nile|ganges)
        _verity_file=build/target/product/security/verity.x509.pem
        # _verity_key_id=$(openssl x509 -in $_verity_file -text | grep keyid | sed 's/://g' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | sed 's/keyid//g')

        # BOARD_KERNEL_CMDLINE+=" veritykeyid=id:$_verity_key_id"
        ;;
    esac

    _ramdisk=$(realpath ~/Downloads/Telegram\ Desktop/debug_initrd.img)
    _ramdisk="/newdata/SoM/initramfs-linux.img"
    #_ramdisk=$(realpath ~/Downloads/initramfs-test-image-qcom-armv8a-20220929073818-999.rootfs.cpio.gz)

    # Platform specific
    case ${_platform} in
    loire)
        # Necessary to find fstab on the ramdisk:
        BOARD_KERNEL_CMDLINE+=" androidboot.boot_devices=soc/7824900.sdhci"
        # Creates a /dev/block/bootdevice link to this device:
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=7824900.sdhci"
        # warning: this makes stdout-path in DTS "work" before UART probes, resulting in dupes
        BOARD_KERNEL_CMDLINE+=" earlycon=msm_serial_dm,0x7af0000"
        # Without this we somehow get dupes as soon as kernel switches to console, afaik because of stdout-path?
        BOARD_KERNEL_CMDLINE+=" console=ttyMSM0"
        # stdout-path in DTS would also keep running otherwise
        # BOARD_KERNEL_CMDLINE+=" keep_bootcon"
        BOARD_KERNEL_CMDLINE+=" maxcpus=4"
        # BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0p51" # userdata
        # BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0p52" # system
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk1" # sdcard
        ;;
    yoshino)
        _recovery_ramdisk=false
        # BOARD_KERNEL_CMDLINE+=" root=/dev/sda64" # vendor
        # BOARD_KERNEL_CMDLINE+=" root=/dev/sda65" # system
        # BOARD_KERNEL_CMDLINE+=" root=/dev/sda66" # userdata
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        ;;
    nile|ganges)
        # BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0p76" # userdata
        # BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0p78" # system_a (too small)
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk1" # sdcard
        # BOARD_KERNEL_CMDLINE+=" androidboot.boot_devices=soc/c0c4000.sdhci"
        # BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=c0c4000.sdhci"
        BOARD_KERNEL_CMDLINE+=" earlycon=msm_serial_dm,0xc170000"
        BOARD_KERNEL_CMDLINE+=" console=ttyMSM0"
        # BOARD_KERNEL_CMDLINE+=" keep_bootcon"
        ;;
    tama)
        _has_dtbo=true
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard

        # BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    kumano)
        _has_dtbo=true

        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        # BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    seine)
        _has_dtbo=true
        _recovery_ramdisk=false

        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        # BOARD_KERNEL_CMDLINE+=" root=/dev/block/mmcblk0p85"
        #BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0p85" # super
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk1" # sdcard
        ;;
    edo)
        _has_dtbo=true
        _recovery_ramdisk=false

        # BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        ;;
    lena)
        _has_dtbo=true
        _recovery_ramdisk=false

        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        # BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk1" # sdcard if main MMC were probed..
        # BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    sagami)
        _has_dtbo=true
        _has_vendor_boot=true
        _mkbootimg_args=(--header_version 1)

        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    nagara)
        _has_dtbo=true
        _has_vendor_boot=true
        _mkbootimg_args=(--header_version 4)
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    murray)
        _has_dtbo=true
        _has_vendor_boot=true
        _mkbootimg_args=(--header_version 3)
        BOARD_KERNEL_CMDLINE+=" root=/dev/mmcblk0" # sdcard
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=4804000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    esac

    # Options
    _permissive=true

    case ${_platform} in
    loire)
        _recovery_ramdisk=false
        ;;
    *)
        # _recovery_ramdisk=true TODO
        BOARD_KERNEL_CMDLINE+=" androidboot.force_normal_boot=1"
        ;;
    esac

    # shellcheck source=./compile.sh
    . "$_self_dir/compile.sh"

    _boot_out=${_device}-boot.img

    # shellcheck source=./create_images.sh
    . "$_self_dir/create_images.sh"

    if [ "$_fastboot_flash" = "true" ]; then
        echo "==> Flashing $_boot_out"
        fastboot flash:raw boot "$_boot_out"
        if [ -n "$_dtbo_out" ]; then
            echo "==> Flashing $_dtbo_out"
            fastboot flash dtbo "$_dtbo_out"
        fi
        if [ -n "$_vendor_boot_out" ]; then
            echo "==> Flashing $_vendor_boot_out"
            fastboot flash vendor_boot "$_vendor_boot_out"
        fi

        echo "==> Rebooting device..."
        fastboot continue || fastboot reboot
    fi

    echo
done
