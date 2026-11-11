#!/bin/sh
# Pluto+ SD boot with the U-Boot 2016.07 of tezuka 0.2.4.
#
# Runs after postimage-sd.sh (configs/plutoplus_shonan*_defconfig). The
# U-Boot 2025.01 BOOT.bin that postimage-sd.sh makes does not start from the
# SD card on our Pluto+ (green LED only, no FPGA DONE, no USB), while the
# tezuka 0.2.4 BOOT.bin (FSBL + 0.2.4 bitstream + U-Boot 2016.07) does. That
# U-Boot imports this build's uEnv.txt and loads this build's bitstream
# (system_top.bin), devicetree and ramdisk, but it cannot unpack the LZMA
# uImage, so the kernel is stored uncompressed.
set -e

BIN_DIR="$1"
SHONAN_DIR="$(dirname "$0")"
SDIMGDIR="${BIN_DIR}/sdimg"

cp -f "${SHONAN_DIR}/legacy-boot/plutoplus-0.2.4-BOOT.bin" "${SDIMGDIR}/BOOT.bin"

# The overclock BOOT_* variants carry the new U-Boot: no use here.
rm -rf "${SDIMGDIR}/overclock"

mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 \
	-n "Linux kernel" -d "${BIN_DIR}/Image" "${SDIMGDIR}/uImage"

# U-Boot banner: the firmware name from post-build.sh instead of the tezuka one
FW_NAME=$(grep '^device-fw ' "${TARGET_DIR}/opt/VERSIONS" | cut -d ' ' -f 2)
sed -i "s/echo \"Version [^\"]*\"/echo \"Version ${FW_NAME}\"/" "${SDIMGDIR}/uEnv.txt"
