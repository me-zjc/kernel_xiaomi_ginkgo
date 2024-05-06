#!/usr/bin/env bash
#
# Copyright (C) 2024 chao
#
# Simple Local Kernel Build Script
#
# Configured for Redmi Note 8 / ginkgo custom kernel source
#
# Setup build env with akhilnarang/scripts repo
#
# Use this script on root of kernel directory

SECONDS=0 # builtin bash timer
TC_DIR="/workspace/toolchain/linux-x86"
CLANG_DIR="$TC_DIR/clang-r498229b"
GCC_64_DIR="/workspace/toolchain/aarch64-linux-android-4.9"
GCC_32_DIR="/workspace/toolchain/arm-linux-androideabi-4.9"
AK3_DIR="/workspace/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"
MAKE_PARAMS="O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm \
        OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- \
        CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi-"

export PATH="$CLANG_DIR/bin:$PATH"
export KBUILD_BUILD_USER="chao"
export KBUILD_BUILD_HOST="BUILD_DOCKER"
export KBUILD_BUILD_VERSION="1"

if ! [ -d "${CLANG_DIR}" ]; then
echo "Clang not found! Cloning to ${CLAN_DIR}..."
if ! git clone --depth=1 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 ${TC_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
echo "gcc not found! Cloning to ${GCC_64_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/me-zjc/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${GCC_64_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
echo "gcc_32 not found! Cloning to ${GCC_32_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/me-zjc/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${GCC_32_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
rm -rf out
fi

mkdir -p out
make $MAKE_PARAMS menuconfig
make $MAKE_PARAMS $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully!\n"
else
echo -e "\nKernel compiled failure!"
exit 1
fi
