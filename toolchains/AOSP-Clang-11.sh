#!/bin/bash

set -eo pipefail

maindir="$(pwd)"
outside="${maindir}/.."

clang="${outside}/aosp_clang11"
gcc64="${outside}/aosp_gcc64_49"
gcc="${outside}/aosp_gcc_49"

case $1 in
  "setup" )
    # Clone compiler
    if [ ! -d $clang ]; then
    git clone --depth=1 https://github.com/TeraaBytee/google-clang $clang
    fi
    if [ ! -d $gcc64 ]; then
    git clone --depth=1 https://github.com/TeraaBytee/aarch64-linux-android-4.9 $gcc64
    fi
    if [ ! -d $gcc ]; then
    git clone --depth=1 https://github.com/TeraaBytee/arm-linux-androideabi-4.9 $gcc
    fi
  ;;

  "build" )
    export PATH="$clang/bin:$gcc64/bin:$gcc/bin:/usr/bin:${PATH}"
    make -j$NJOBS O=out CC=clang LD=ld.lld ARCH=arm64 SUBARCH=arm64 $2

    # Generate autoconf.h and auto.conf before inspecting CONFIG_* macros.
    make -j$NJOBS O=out prepare

    echo "===== CONFIG DIAGNOSTICS ====="
    test -s out/.config || { echo "ERROR: out/.config was not generated"; exit 1; }
    echo "--- kernel config ---"
    grep -E '^(CONFIG_KDP_NS|CONFIG_RUSTUH_KDP_NS)=' out/.config || true
    for f in out/include/config/auto.conf out/include/generated/autoconf.h; do
      echo "--- $f ---"
      if [ -f "$f" ]; then
        grep -n -E 'CONFIG_KDP_NS|CONFIG_RUSTUH_KDP_NS' "$f" || echo "Neither KDP NS symbol is present"
      else
        echo "MISSING"
      fi
    done
    echo "--- mount struct ---"
    grep -n -B3 -A3 'struct vfsmount \*mnt;' fs/mount.h || true
    echo "--- namespace access ---"
    grep -n -B4 -A4 'mnt->mnt.mnt_flags.*MNT_LOCKED' fs/namespace.c || true
    grep -n -B4 -A4 'mnt->mnt->mnt_flags.*MNT_LOCKED' fs/namespace.c || true
    echo "--- source revision / changes ---"
    git rev-parse HEAD
    git status --short -- fs/namespace.c fs/mount.h
    echo "===== END CONFIG DIAGNOSTICS ====="
    make -j$NJOBS O=out \
      CROSS_COMPILE="aarch64-linux-android-" \
      CROSS_COMPILE_ARM32="arm-linux-androideabi-" \
      CROSS_COMPILE_COMPAT="arm-linux-androideabi-" \
      CLANG_TRIPLE="aarch64-linux-gnu-" \
      LD_LIBRARY_PATH="$clang/lib64:$LD_LIBRARY_PATH" \
      CC=clang \
      LD=ld.lld \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh clang ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac
