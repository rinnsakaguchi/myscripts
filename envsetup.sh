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
# We start in scripts, so like, don't clone things there
KERNELDIR="$(pwd)"
SCRIPTS=${KERNELDIR}/kernelscripts
OUTDIR=${KERNELDIR}/out
COMPILER_TYPES=clang

# Pick your poison
if [[ "${COMPILER_TYPES}" =~ "clang" ]]; then
        git clone https://github.com/RaphielGang/aosp-clang.git "${KERNELDIR}"/clang
        git clone https://github.com/KudProject/aarch64-linux-android-4.9.git "${KERNELDIR}"/gcc
        git clone https://github.com/KudProject/arm-linux-androideabi-4.9.git "${KERNELDIR}"/gcc32
        COMPILER_STRING='AARCH64 : GCC 4.9
       ARM    : GCC 4.9
       CLANG  : GOOGLE CLANG'
	COMPILER_TYPE='clang'
else
        # Default to GCC from Arter
        git clone https://github.com/arter97/arm64-gcc --depth=1 "${KERNELDIR}/gcc"
        git clone https://github.com/arter97/arm32-gcc --depth=1 "${KERNELDIR}/gcc32"
        COMPILER_STRING='GCC 9.x'
	COMPILER_TYPE='GCC9.x'
fi

export COMPILER_STRING COMPILER_TYPE KERNELDIR SCRIPTS OUTDIR

git clone https://github.com/fabianonline/telegram.sh/ telegram

# Export Telegram.sh
TELEGRAM=${KERNELDIR}/telegram/telegram

export TELEGRAM JOBS
