#!/usr/bin/env bash
#
# Copyright (C) 2019 nysascape
#
# Licensed under the Raphielscape Public License, Version 1.d (the "License");
# you may not use this file except in compliance with the License.
#
# Probably the 3rd bad apple coming
# Enviroment variables

# Export KERNELDIR as en environment-wide thingy
# We start in scripts, so like, don't clone things
KERNELDIR="$(pwd)"
TC_DIR="${LOCAL_DIR}toolchain"
CLANG_DIR="${TC_DIR}/clang-rastamod"
SCRIPTS=${KERNELDIR}/kernelscripts
OUTDIR=${KERNELDIR}/out
COMPILER_TYPES=clang
GCC_DIR="${LOCAL_DIR}toolchain/aarch64-linux-android-4.9" # Doesn't needed if use proton-clang
GCC32_DIR="${LOCAL_DIR}toolchain/arm-linux-androideabi-4.9" # Doesn't needed if use proton-clang

# Pick your poison
if [[ "${COMPILER_TYPES}" =~ "clang" ]]; then
        git clone --depth=1 -b clang-21.0 https://gitlab.com/kutemeikito/rastamod69-clang  "${CLANG_DIR}"
	git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git "${GCC_DIR}"
    git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git "${GCC32_DIR}"
	COMPILER_STRING='Rasta clang 21'
        COMPILER_TYPE='Rasta clang 21'
fi    

export COMPILER_STRING COMPILER_TYPE KERNELDIR SCRIPTS OUTDIR

git clone https://github.com/fabianonline/telegram.sh/ telegram

# Export Telegram.sh
TELEGRAM=${KERNELDIR}/telegram/telegram

export TELEGRAM JOBS
