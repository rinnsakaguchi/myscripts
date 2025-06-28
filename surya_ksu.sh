#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export TELEGRAM_TOKEN=7485743487:AAEKPw9ubSKZKit9BDHfNJSTWcWax4STUZs
export ANYKERNEL=$(pwd)/anykernel3

# Avoid hardcoding things
KERNEL=Perf-qgki
DEFCONFIG=surya_ksu_defconfig
CIPROVIDER=CircleCI
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"

# Get total RAM
RAM_INFO=$(free -m)
TOTAL_RAM=$(echo "$RAM_INFO" | awk '/^Mem:/{print $2}')
TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_RAM/1024}")
export TOTAL_RAM_GB

# Get all cores of CPU
PROCS=$(nproc --all)
export PROCS

# Get CPU name
export CPU_NAME="$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')"

# Get distro name
DISTRO=$(source /etc/os-release && echo ${NAME})

# Export custom KBUILD
export OUTFILE=${OUTDIR}/arch/arm64/boot/Image.gz-dtb
export OUTFILE=${OUTDIR}/arch/arm64/boot/dtb.img
export OUTFILE=${OUTDIR}/arch/arm64/boot/dtbo.img
export KBUILD_BUILD_USER=mahiroo
export KBUILD_BUILD_HOST=android-build
export CLANG_PATH=${PWD}/clang
export PATH=${CLANG_PATH}/bin:${PATH}
export ARCH=arm64
export DATE=$(TZ=Asia/Jakarta date)
# Kernel groups
CI_CHANNEL=-1002354747626

# Kernel revision
KERNELRELEASE=surya

# Clang is annoying
PATH="${PWD}/clang/bin:${PATH}"

# Set date and time
DATE=$(TZ=Asia/Jakarta date)

# Set date and time for zip name
ZIP_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")

# Function to replace defconfig versioning
setversioning() {

# For staging branch
            KERNELNAME="${KERNEL}-${KERNELRELEASE}-KSU-${ZIP_DATE}"
	    
    # Export our new localversion and zipnames
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

# Send to channel
tg_channelcast() {
    "${TELEGRAM}" -c "${CI_CHANNEL}" -H \
    "$(2
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# Make the kernel
makekernel() {
    # Clean any old AnyKernel
    rm -rf ${ANYKERNEL}
    git clone https://github.com/rinnsakaguchi/AnyKernel3.git -b FSociety anykernel3
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${COMPILER_TYPE}" =~ "clang"* ]]; then
        make -j$(nproc --all) \
	O=out \
	CC="${ccache_} clang" \
	AS=llvm-as \
	LD=ld.lld \
	AR=llvm-ar \
	NM=llvm-nm \
	STRIP=llvm-strip \
	OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump \
	CROSS_COMPILE="${PWD}/gcc/bin/aarch64-none-linux-gnu-" \
	CROSS_COMPILE_ARM32="${PWD}/gcc32/bin/arm-none-linux-gnueabihf-"
    else
	    make -j$(nproc --all) O=out ARCH=arm64 CROSS_COMPILE="${PWD}/gcc/bin/aarch64-elf-" CROSS_COMPILE_ARM32="${PWD}/gcc32/bin/arm-eabi-"
    fi

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
    cp "${OUTDIR}"/arch/arm64/boot/dtb.img "${ANYKERNEL}"/
    cp "${OUTDIR}"/arch/arm64/boot/dtbo.img "${ANYKERNEL}"/
   
    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" *

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -c "${CI_CHANNEL}"

    # Go back for any extra builds
    cd ..
}

# Ship China firmware builds
setksu() {
    export KSU=KSU
    # Pick DSP change
    sed -i 's/CONFIG_KSU=n/CONFIG_KSU=y/g' arch/arm64/configs/${DEFCONFIG}
    echo -e "KSU ready"
}

# Ship China firmware builds
clearout() {
    # Pick DSP change
    rm -rf out
    mkdir -p out
}

#Setver 2 for ksu
setver2() {
    KERNELNAME="${KERNEL}-${KERNELRELEASE}-KSU-${ZIP_DATE}"
    export KERNELTYPE KERNELNAME
    export TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
    export ZIPNAME="${KERNELNAME}.zip"
}

## Start the kernel buildflow ##
setversioning
tg_channelcast "Docker OS: <code>$DISTRO</code>" \
        "Compiler: <code>${COMPILER_STRING}</code>" \
	"Device: <code>Poco X3 NFC (surya)</code>" \
	"Linux Version: <code>$(make kernelversion)</code>" \
        "Date: <code>$DATE</code>" \
	"Branch: <code>${PARSE_BRANCH}</code>" \
        "Host RAM Count: <code>${TOTAL_RAM_GB}</code>" \
        "Pipeline Host: <code>${KBUILD_BUILD_HOST}</code>" \
        "Host CPU Name: <code>${CPU_NAME}</code>" \
        "Host Core Count: <code>${PROCS} core(s)</code>" \
	"Commit point: <code>${COMMIT_POINT}</code>"
START=$(date +"%s")
makekernel || exit 1
shipkernel
setksu
setver2
makekernel || exit 1
shipkernel
END=$(date +"%s")
DIFF=$(( END - START ))
tg_channelcast "Build for Poco X3 NFC with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
