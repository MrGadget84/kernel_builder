#!/bin/bash

set -o pipefail

maindir="$(pwd)"
outside="${maindir}/.."
dir="${outside}/NeutronClang"

case "$1" in
  "setup")
    # Reuse a complete toolchain; repair an interrupted/incomplete install.
    if [[ ! -x "${dir}/bin/clang" || ! -x "${dir}/bin/ld.lld" ]]; then
      mkdir -p "${dir}" || exit 1
      cd "${dir}" || exit 1
      curl -fL --retry 3 --retry-delay 2 -o antman "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" || exit 1
      bash antman -S=latest || exit 1
      [[ -x "${dir}/bin/clang" && -x "${dir}/bin/ld.lld" ]] || {
        echo "Neutron Clang installation did not produce clang and ld.lld."
        exit 1
      }
    fi
    ;;
  "build")
    export PATH="${dir}/bin:/usr/bin:${PATH}"

    command -v clang >/dev/null 2>&1 || { echo "clang not found in Neutron toolchain"; exit 1; }
    command -v ld.lld >/dev/null 2>&1 || { echo "ld.lld not found in Neutron toolchain"; exit 1; }

    make -j"${NJOBS}" O=out ARCH=arm64 SUBARCH=arm64 \
      CC=clang LD=ld.lld "$2" || exit 1

    make -j"${NJOBS}" O=out \
      ARCH=arm64 SUBARCH=arm64 \
      CROSS_COMPILE="aarch64-linux-gnu-" \
      CROSS_COMPILE_ARM32="arm-linux-gnu-" \
      CROSS_COMPILE_COMPAT="arm-linux-gnu-" \
      CLANG_TRIPLE="aarch64-linux-gnu-" \
      CC=clang \
      LD=ld.lld \
      NM=llvm-nm \
      AR=llvm-ar \
      STRIP=llvm-strip \
      OBJCOPY=llvm-objcopy \
      OBJDUMP=llvm-objdump \
      READELF=llvm-readelf \
      LLVM_IAS=1 \
      HOSTCC=clang \
      HOSTCXX=clang++ \
      HOSTLD=ld.lld \
      HOSTAR=llvm-ar \
      KCFLAGS="-Wno-macro-redefined" \
      2>&1 | tee "${CUR_TOOLCHAIN}.log"

    sh "${outside}/ver_toolchain.sh" clang ld.lld > "${CUR_TOOLCHAIN}.info"
    ;;
  *)
    echo "Usage: $0 {setup|build} [defconfig]"
    exit 2
    ;;
esac
