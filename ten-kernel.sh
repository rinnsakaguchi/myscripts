#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export TELEGRAM_TOKEN=1157809262:AAHNbCHG-XcjgpGuDflcTX8Z_OJiXcjdDr0
export ANYKERNEL=$(pwd)/anykernel3

# Avoid hardcoding things
KERNEL=PREDATOR
DEFCONFIG=vendor/whyred_defconfig
DEVICE=whyred
CIPROVIDER=CircleCI
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"

# Export custom KBUILD
export KBUILD_BUILD_USER=iqbal
export KBUILD_BUILD_HOST=CircleCI
export OUTFILE=${OUTDIR}/arch/arm64/boot/Image.gz-dtb

# Kernel groups
CI_CHANNEL=-1001488385343

# Kernel & Clang Setup
CLANG_DIR="$KERNEL_DIR/clang"
export PATH="$KERNEL_DIR/clang/bin:$PATH"
KBUILD_COMPILER_STRING="$("$CLANG_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# Set default local datetime
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
BUILD_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")

# Clang is annoying
PATH="${KERNELDIR}/clang/bin:${PATH}"

# Kernel revision
KERNELTYPE=EAS
KERNELRELEASE=whyred

# Function to replace defconfig versioning
setversioning() {

    # For staging branch
    KERNELNAME="${KERNEL}-${KERNELTYPE}-${KERNELRELEASE}-${BUILD_DATE}"

    # Export our new localversion and zipnames
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

# Send to channel
tg_channelcast() {
    "${TELEGRAM}" -c "${CI_CHANNEL}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# Fix long kernel strings
kernelstringfix() {
    git config --global user.name "predator112"
    git config --global user.email "mi460334@gmail.com"
    git add .
    git commit -m "stop adding dirty"
}

# Make the kernel
makekernel() {
    # Clean any old AnyKernel
    rm -rf ${ANYKERNEL}
    git clone https://github.com/PREDATOR-project/AnyKernel3.git -b BangBroz-oldcam anykernel3
    kernelstringfix
    make -j"$(nproc --all)" O=out ${DEFCONFIG} \
          CC=clang \
          AR=llvm-ar \
          NM=llvm-nm \
          OBJCOPY=llvm-objcopy \
          OBJDUMP=llvm-objdump \
          STRIP=llvm-strip \
          CROSS_COMPILE=aarch64-linux-gnu- \
          CROSS_COMPILE_ARM32=arm-linux-gnueabi-

    # Check if compilation is done successfully.
    if ! [ -f "${OUTFILE}" ]; then
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Kernel compilation failed, See buildlog to fix errors"
	    tg_channelcast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check ${CIPROVIDER} for errors!"
	    exit 1
    fi
}

# Ship the compiled kernel
shipkernel() {
    # Copy compiled kernel
    cp "${OUTDIR}"/arch/arm64/boot/Image.gz-dtb "${ANYKERNEL}"/

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" *

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -c "${CI_CHANNEL}"

    # Go back for any extra builds
    cd ..
}

## Start the kernel buildflow ##
setversioning
tg_channelcast "<b>$CIRCLE_BUILD_NUM CI Build Triggered</b>" \
        "Compiler: <code>${COMPILER_STRING}</code>" \
	"Device: ${DEVICE}" \
	"Kernel: <code>${KERNEL}, ${KERNELRELEASE}</code>" \
	"Linux Version: <code>$(make kernelversion)</code>" \
	"Branch: <code>${PARSE_BRANCH}</code>" \
	"Commit point: <code>${COMMIT_POINT}</code>" \
	"Clocked at: <code>$(date +%Y%m%d-%H%M)</code>"
START=$(date +"%s")
makekernel || exit 1
shipkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_channelcast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
