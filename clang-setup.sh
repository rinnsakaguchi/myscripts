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
SCRIPTS=${KERNELDIR}/kernelscripts
OUTDIR=${KERNELDIR}/out
COMPILER_TYPES=clang

# Pick your poison
if [[ "${COMPILER_TYPES}" =~ "clang" ]]; then
        git clone --depth=1 https://gitlab.com/predator112/predator_clang.git -b clang "${KERNELDIR}"/clang
	COMPILER_STRING='Predator clang'
        COMPILER_TYPE='Predator clang'
else
        # Default to GCC from Arter
        git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 -b lineage-19.1 --depth=1 "${KERNELDIR}/gcc"
        git clone https://github.com/kdrag0n/arm-eabi-gcc --depth=1 "${KERNELDIR}/gcc32"
        COMPILER_STRING='GCC 9.x'
	COMPILER_TYPE='GCC 9.x'
fi

export COMPILER_STRING COMPILER_TYPE KERNELDIR SCRIPTS OUTDIR

git clone https://github.com/fabianonline/telegram.sh/ telegram

# Export Telegram.sh
TELEGRAM=${KERNELDIR}/telegram/telegram

export TELEGRAM JOBS
