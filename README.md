# Out-Of-Tree kernel build scripts

Or "out-of-tree", as these are still in a way dependent on the Android build tree.
But paths can easily be changed and the relevant tools cloned/copied/installed without AOSP tree.

These scripts build the Sony Open Devices kernel outside of the tree and generate a `boot.img` as well as a `dtbo.img`. It saves a tremendous amount of time since the AOSP build system easily takes 15-20 seconds to read makefiles, decides it doesn't need to regenerate them, call `mkbootimg` and deliver the `boot.img`. Calling this tool outside of the build results in much quicker iteration.

Currently the path to the compilers, ramdisks and kernels are hardcoded, but easy to change.

## Usage:

1. Clone directly in the root of an AOSP tree (or point the `ANDROID_BUILD_TOP` environment variable to this root);
2. Call `./oot/oot.sh <device name>` (use `-h` to see more options);
3. Flash the images. For simplicity, you can also add the `-f` option to the command, that will flash and `fastboot reboot` the device after building.

## TODO:
- Expand platforms passed to this script (ie. passing `kumano` builds `griffin` and `bahamut`);
- Options to specify alternate ramdisk and kernel directory?
