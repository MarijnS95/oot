#! /usr/bin/bash

# TODO: Move stuff to platform-specific file and/or use switchcase?

# Device specific
_platform=ganges
_device=mermaid

_verity_file=build/target/product/security/verity.x509.pem
_verity_key_id=$(openssl x509 -in $_verity_file -text | grep keyid | sed 's/://g' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | sed 's/keyid//g')

# Image args
BOARD_KERNEL_BASE=0x00000000
BOARD_KERNEL_PAGESIZE=4096
BOARD_KERNEL_TAGS_OFFSET=0x01E00000
BOARD_RAMDISK_OFFSET=0x02000000
BOARD_KERNEL_CMDLINE="lpm_levels.sleep_disabled=1 service_locator.enable=1 androidboot.memcg=1 msm_rtb.filter=0x3F ehci-hcd.park=3 coherent_pool=8M sched_enable_power_aware=1 user_debug=31 printk.devkmsg=on kpti=0 androidboot.hardware=$_device buildvariant=userdebug veritykeyid=id:$_verity_key_id"

# Options
# _permissive=true
_compiler=linaro_gcc

_self_dir=$(realpath $(dirname "$0"))
. $_self_dir/compile.sh
