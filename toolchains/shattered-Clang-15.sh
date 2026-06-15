#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

dir="${outside}/shatteredClang15"

case $1 in
  "setup" )
    # Clone compiler
    if [[ ! -d "${dir}" ]]; then
      mkdir ${dir} && cd ${dir}
      curl -Lo a.tar.gz "https://github.com/erabye/shattered-clang/releases/download/shattered-Clang-15.0.7/shattered-Clang-15.0.7.tar.gz"
      tar -zxf a.tar.gz --strip-components=1 || tar -zxf a.tar.gz
    fi
  ;;
  
  "build" )
    export PATH="$clang/bin:$gcc64/bin:$gcc/bin:/usr/bin:${PATH}"
    sed -i 's/info BTF/return 0/g' scripts/link-vmlinux.sh 2>/dev/null || :
    sed -i 's/cmd btf/return 0/g' scripts/link-vmlinux.sh 2>/dev/null || :
    git submodule update --init --recursive
    make O=out ARCH=arm64 a32_lineage_defconfig
    make O=out ARCH=arm64 olddefconfig
    make -j$NJOBS O=out \
      CROSS_COMPILE="aarch64-linux-android-" \
      CROSS_COMPILE_ARM32="arm-linux-androideabi-" \
      CROSS_COMPILE_COMPAT="arm-linux-androideabi-" \
      CLANG_TRIPLE="aarch64-linux-gnu-" \
      LD_LIBRARY_PATH="$clang/lib64:$LD_LIBRABRY_PATH" \
      CC="clang -w" \
      LD=ld.lld \
      NM=llvm-nm \
      AR=llvm-ar \
      STRIP=llvm-strip \
      OBJCOPY=llvm-objcopy \
      OBJDUMP=llvm-objdump \
      READELF=llvm-readelf \
      LLVM_IAS=1 \
      HOSTCC="clang -w" \
      HOSTCXX="clang++ -w" \
      HOSTLD=ld.lld \
      HOSTAR=llvm-ar \
      KCFLAGS="-Wno-deprecated-non-prototype -Wno-strict-prototypes -Wno-int-conversion -Wno-unused-variable -Wno-fortify-source -Wno-error" \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh clang ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac
