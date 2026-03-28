#!/bin/bash
# toolchains/s3ve3g-gcc.sh

set -e

case $1 in
  "setup" )
    INSTALL_DIR="/opt/gcc-4.9.3"
    TOOLCHAIN_URL="https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz"
    TARBALL="gcc-4.9.3.tar.xz"
    
    sudo mkdir -p "$INSTALL_DIR"
    
    if [ ! -f "$TARBALL" ]; then
      wget -O "$TARBALL" "$TOOLCHAIN_URL"
    fi
    
    sudo tar -xf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1
    
    cd "$INSTALL_DIR/bin"
    for tool in arm-linux-gnueabihf-*; do
      new_tool="${tool/arm-linux-gnueabihf/arm-eabi}"
      sudo ln -sf "$tool" "$new_tool"
    done
    cd -
    
    export PATH="$INSTALL_DIR/bin:$PATH"
    echo "GCC installed:"
    arm-eabi-gcc --version
    ;;

  "build" )
    export ARCH=arm
    export SUBARCH=arm
    export CROSS_COMPILE=arm-eabi-
    export PATH="/opt/gcc-4.9.3/bin:$PATH"
    
    cd "${maindir}"
    
    echo "Building in: $(pwd)"
    
    mkdir -p out
    
    # Исправляем gcc-wrapper.py
    if [ -f scripts/gcc-wrapper.py ]; then
      sed -i 's/print "\(.*\)"/print("\1")/g' scripts/gcc-wrapper.py
      sed -i 's/print \(.*\),/print(\1, end=" ")/g' scripts/gcc-wrapper.py
    fi
    
    # ПРОСТО КОПИРУЕМ ГОТОВЫЙ dtc ИЗ СИСТЕМЫ
    echo "Using system dtc instead of building..."
    if command -v dtc &> /dev/null; then
      mkdir -p scripts/dtc
      cp $(which dtc) scripts/dtc/dtc 2>/dev/null || true
    fi
    
    # ИЛИ ПРОСТО ОТКЛЮЧАЕМ СБОРКУ dtc
    echo "Disabling dtc build..."
    sed -i 's/^hostprogs-.*/hostprogs-$(CONFIG_DTC) :=/' scripts/dtc/Makefile
    sed -i 's/^always.*/always-$(CONFIG_DTC) :=/' scripts/dtc/Makefile
    
    DEFCONFIG="$2"
    if [ -z "$DEFCONFIG" ]; then
      DEFCONFIG="cyanogenmod_s3ve3g_defconfig"
    fi
    
    echo "Using defconfig: $DEFCONFIG"
    
    if [ ! -f "arch/arm/configs/$DEFCONFIG" ]; then
      echo "ERROR: Defconfig $DEFCONFIG not found!"
      ls arch/arm/configs/ | head -20
      exit 1
    fi
    
    make O=out ARCH=arm "$DEFCONFIG"
    
    echo "Building kernel with ${NJOBS:-4} jobs..."
    make -j${NJOBS:-4} O=out ARCH=arm 2>&1 | tee build.log
    
    if [ -f out/arch/arm/boot/zImage ]; then
      export out_image="${maindir}/out/arch/arm/boot/zImage"
      export out_dtb="${maindir}/out/arch/arm/boot/dt.img"
      echo "Build successful!"
      ls -lh out/arch/arm/boot/zImage
    else
      echo "Build failed!"
      exit 1
    fi
    ;;
    
  * )
    echo "Usage: $0 {setup|build} [defconfig]"
    exit 1
    ;;
esac
