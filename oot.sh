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
    echo -e '\t-s                     Separate per-device kernel tmp dir instead of per-platform.'
    echo -e '\t-h, --help             Show the usage of the tool'
}


while getopts 'c:fsh-:' OPT; do
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
    s)
        _separate_kernel_dir=true
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

    BOARD_KERNEL_CMDLINE+=" lpm_levels.sleep_disabled=1"
    BOARD_KERNEL_CMDLINE+=" service_locator.enable=1"
    BOARD_KERNEL_CMDLINE+=" androidboot.hardware=${_device}"

    _kernel_major=4
    _kernel_minor=14

    # Device specific
    case ${_device} in
    lilac|maple|poplar)
        _platform=yoshino
        ;;
    discovery|pioneer|voyager)
        _platform=nile
        ;;
    akari|akatsuki|apollo)
        _platform=tama
        ;;
    kirin|mermaid)
        _platform=ganges
        ;;
    bahamut|griffin)
        _platform=kumano
        ;;
    pdx201)
        _platform=seine
        ;;
    pdx20[36])
        _platform=edo
        _kernel_minor=19
        ;;
    pdx213)
        _platform=lena
        _kernel_minor=19
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
        _verity_key_id=$(openssl x509 -in $_verity_file -text | grep keyid | sed 's/://g' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | sed 's/keyid//g')

        BOARD_KERNEL_CMDLINE+=" veritykeyid=id:$_verity_key_id"
        ;;
    esac

    # Platform specific
    case ${_platform} in
    yoshino)
        _recovery_ramdisk=false
        ;;
    tama)
        _has_dtbo=true

        BOARD_KERNEL_CMDLINE+=" msm_drm.dsi_display0=dsi_panel_somc_${_platform}_cmd:config0"
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    kumano)
        _has_dtbo=true

        BOARD_KERNEL_CMDLINE+=" msm_drm.blhack_dsi_display0=dsi_panel_somc_${_platform}_cmd:config0"
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    seine)
        _has_dtbo=true
        _recovery_ramdisk=false

        BOARD_KERNEL_CMDLINE+=" msm_drm.blhack_dsi_display0=dsi_panel_somc_${_platform}_cmd:config0"
        ;;
    edo|lena)
        _has_dtbo=true
        _recovery_ramdisk=false

        BOARD_KERNEL_CMDLINE+=" msm_drm.blhack_dsi_display0=dsi_panel_somc_${_platform}_cmd:config0"
        BOARD_KERNEL_CMDLINE+=" androidboot.bootdevice=1d84000.ufshc"
        BOARD_KERNEL_CMDLINE+=" swiotlb=2048"
        ;;
    esac


    # Options
    # _permissive=true

    # shellcheck source=./compile.sh
    . "$_self_dir/compile.sh"

    _boot_out=${_device}-boot.img

    # shellcheck source=./create_images.sh
    . "$_self_dir/create_images.sh"

    if [ "$_fastboot_flash" = "true" ]; then
        echo "==> Flashing $_boot_out"
        fastboot flash boot "$_boot_out"
        if [ "$_has_dtbo" = "true" ]; then
            echo "==> Flashing $_dtbo_out"
            fastboot flash dtbo "$_dtbo_out"
        fi

        echo "==> Rebooting device..."
        fastboot continue || fastboot reboot
    fi

    echo
done
