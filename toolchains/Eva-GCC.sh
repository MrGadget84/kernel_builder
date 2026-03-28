#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

GCC64="${outside}/gcc-arm64"
GCC32="${outside}/gcc-arm"

case $1 in
  "setup" )
    cd "${outside}"
    if [[ ! -d "${GCC64}" ]]; then
      curl -Lo gcc-arm64.tar.xz $(curl -s https://api.github.com/repos/mvaisakh/gcc-build/releases/latest | grep browser_download_url | cut -d'"' -f4 | grep 'gcc-arm64-')
      tar -xf gcc-arm64.tar.xz
      chmod +x "${GCC64}"/bin/*
    fi
    if [[ ! -d "${GCC32}" ]]; then
      curl -Lo gcc-arm.tar.xz $(curl -s https://api.github.com/repos/mvaisakh/gcc-build/releases/latest | grep browser_download_url | cut -d'"' -f4 | grep 'gcc-arm-')
      tar -xf gcc-arm.tar.xz
      chmod +x "${GCC32}"/bin/*
    fi
  ;;

  "build" )
    export PATH="${GCC32}/bin:/usr/bin:${PATH}"
    mkdir -p out
    make -j$NJOBS O=out ARCH=arm SUBARCH=arm $2
      ARCH=arm \
      CROSS_COMPILE=arm-eabi- \
      CC=arm-eabi-gcc \
      LD=arm-eabi-ld \
      AR=arm-eabi-ar \
      NM=arm-eabi-nm \
      OBJCOPY=arm-eabi-objcopy \
      OBJDUMP=arm-eabi-objdump \
      STRIP=arm-eabi-strip \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh arm-eabi-gcc --version | head -n 1 > ${CUR_TOOLCHAIN}.info
  ;;
esac
