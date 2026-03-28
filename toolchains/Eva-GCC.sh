#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

GCC32="${outside}/gcc-arm"

case $1 in
  "setup" )
    cd "${outside}"
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
    make -j$NJOBS O=out \
      CROSS_COMPILE=arm-eabi- \
      LD="${GCC64}"/bin/arm-eabi-ld.lld \
      AR=arm-eabi-ar \
      AS=arm-eabi-as \
      NM=arm-eabi-nm \
      OBJDUMP=arm-eabi-objdump \
      OBJCOPY=arm-eabi-objcopy \
      CC=arm-eabi-gcc \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh arm-eabi-gcc arm-eabi-ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac
