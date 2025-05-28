#!/usr/bin/env bash
# Copyright (C) 2019-2020 Jago Gardiner (nysascape)
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# CI build script

# Needed exports
export ANYKERNEL=$(pwd)/anykernel3

# Avoid hardcoding things
KERNEL=Hyper
DEFCONFIG=surya_ksu_defconfig
CIPROVIDER=Github
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"
CHEAD="$(git rev-parse --short HEAD)"
LATEST_COMMIT="[$COMMIT_POINT](https://github.com/rinnsakaguchi/kernel_surya/commit/$CHEAD)"

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
export KBUILD_BUILD_HOST=android@builder
export CLANG_PATH=${KERNELDIR}/clang/clang-r498229b
export PATH=${CLANG_PATH}/bin:${PATH}
export ARCH=arm64
export DATE=$(TZ=Asia/Jakarta date)
# Telegram
CHATID="-1002354747626" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="7485743487:AAEKPw9ubSKZKit9BDHfNJSTWcWax4STUZs"

# Kernel revision
KERNELRELEASE=surya

# Clang is annoying
PATH="${KERNELDIR}/clang/clang-r498229b/bin:${PATH}"

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

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/fabianonline/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram
tg_cast() {
	curl -s -X POST https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendMessage -d disable_web_page_preview="true" -d chat_id="$CHATID" -d "parse_mode=MARKDOWN" -d text="$(
		for POST in "${@}"; do
			echo "${POST}"
		done
	)" &> /dev/null
}
tg_ship() {
    "${TELEGRAM}" -f "${ZIPNAME}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
                for POST in "${@}"; do
                        echo "${POST}"
                done
    )"
}
tg_fail() {
    "${TELEGRAM}" -f "${LOGS}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
                for POST in "${@}"; do
                        echo "${POST}"
                done
    )"
}

# Patch Defconfig
patch_config() {
    sed -i "s/${KERNELTYPE}/${KERNELTYPE}-TEST/g" "${KERNEL_DIR}/arch/arm64/configs/${DEFCONFIG}"
    sed -i 's/CONFIG_THINLTO=y/CONFIG_THINLTO=n/g' arch/arm64/configs/"${DEFCONFIG}"
    sed -i 's/# CONFIG_LOCALVERSION_AUTO is not set/CONFIG_LOCALVERSION_AUTO=y/g' arch/arm64/configs/"${DEFCONFIG}"
    sed -i 's/# CONFIG_LOCALVERSION_BRANCH_SHA is not set/CONFIG_LOCALVERSION_AUTO=y/g' arch/arm64/configs/"${DEFCONFIG}"
}

# Costumize
patch_config
versioning
KERNEL="Predator:[Akane]"
DEVICE="Surya"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}-$(date +%y%m%d-%H%M)"
TEMPZIPNAME="${KERNELNAME}-unsigned.zip"
ZIPNAME="${KERNELNAME}.zip"

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Build Failed
build_failed() {
	    END=$(date +"%s")
	    DIFF=$(( END - START ))
	    echo -e "Kernel compilation failed, See buildlog to fix errors"
	    tg_fail "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!"
	    exit 1
}

# Make the kernel
makekernel() {
    # Clean any old AnyKernel
    rm -rf ${ANYKERNEL}
    git clone https://github.com/Yuddciel/AnyKernel3.git -b FSociety anykernel3
    kernelstringfix
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
	CROSS_COMPILE="${KERNELDIR}/gcc/bin/aarch64-none-linux-gnu-" \
	CROSS_COMPILE_ARM32="${KERNELDIR}/gcc32/bin/arm-none-linux-gnueabihf-"
    else
	    make -j$(nproc --all) O=out ARCH=arm64 CROSS_COMPILE="${KERNELDIR}/gcc/bin/aarch64-elf-" CROSS_COMPILE_ARM32="${KERNELDIR}/gcc32/bin/arm-eabi-"
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
    tg_ship "<b>-------- $DRONE_BUILD_NUMBER Build Succeed --------</b>" \
            "" \
            "<b>Device:</b> ${DEVICE}" \
            "<b>Version:</b> ${KERNELTYPE}" \
            "<b>Commit Head:</b> ${CHEAD}" \
            "<b>Time elapsed:</b> $((DIFF / 60)):$((DIFF % 60))" \
            "" \
            "Leave a comment below if encountered any bugs!"
}

# Starting
NOW=$(date +%d/%m/%Y-%H:%M)
START=$(date +"%s")
tg_cast "*$DRONE_BUILD_NUMBER CI Build Triggered*" \
	"Compiling with *$(nproc --all)* CPUs" \
	"-----------------------------------------" \
	"*Compiler:* ${CSTRING}" \
	"*Device:* ${DEVICE}" \
	"*Kernel:* ${KERNEL}" \
	"*Version:* ${KERNELTYPE}" \
	"*Linux Version:* $(make kernelversion)" \
	"*Pipeline Host:* <code>${KBUILD_BUILD_HOST}</code>" \
    "*Host CPU Name:* <code>${CPU_NAME}</code>" \
    "*Host Core Count:* <code>${PROCS} core(s)</code>" \
	"*Branch:* ${DRONE_BRANCH}" \
	"*Clocked at:* ${NOW}" \
	"*Latest commit:* ${LATEST_COMMIT}" \
 	"------------------------------------------" \
	"${LOGS_URL}"

makekernel

