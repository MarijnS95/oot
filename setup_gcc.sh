#! /usr/bin/bash

_cross_compile="$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"

_make_args+=" CROSS_COMPILE=$_cross_compile"
