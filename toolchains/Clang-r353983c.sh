#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

clang="${outside}/aosp_clang11"
gcc64="${outside}/aosp_gcc64_49"
gcc="${outside}/aosp_gcc_49"

case $1 in
  "setup" )
    # Clone compiler
    if [ ! -d $clang ]; then
    git clone --depth=1 https://github.com/dandelion64-Archives/clang-r353983c $clang
    fi
    if [ ! -d $gcc64 ]; then
    git clone --depth=1 https://github.com/dandelion64-Archives/aarch64-linux-android-4.9 $gcc64
    fi
    if [ ! -d $gcc ]; then
    git clone --depth=1 https://github.com/dandelion64-Archives/arm-linux-androideabi-4.9 $gcc
    fi
  ;;

  "build" )
    export PATH="$clang/bin:$gcc64/bin:$gcc/bin:/usr/bin:${PATH}"
    make -j$NJOBS O=out LD=ld.lld ARCH=arm SUBARCH=arm $2
    make -j$NJOBS O=out LD=ld.lld ARCH=arm SUBARCH=arm oldconfig
    make -j$NJOBS O=out \
      CROSS_COMPILE="arm-linux-androideabi-" \
      CROSS_COMPILE_COMPAT="arm-linux-androideabi-" \
      CLANG_TRIPLE="arm-linux-gnueabi-" \
      LD_LIBRARY_PATH="$clang/lib64:$LD_LIBRARY_PATH" \
      LD=ld.lld \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh clang ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac
